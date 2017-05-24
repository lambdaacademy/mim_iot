defmodule UcaLib.Worker do
  use GenServer
  use Romeo.XML
  require Logger

  alias Romeo.Connection, as: Conn
  alias Romeo.{Stanza, JID, XML}
  alias Romeo.Stanza.{Presence, IQ, Message}

  defmodule State do
    defstruct conn_pid: nil,
      conn_ready: false,
      available_resources: MapSet.new,
      full_jid: nil,
      resource: nil,
      pending_request: nil,
      subs: %{},
      pubsub_service: nil
  end

  # API

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def send_presence_available(pid) do
    GenServer.call(pid, :send_presence_available)
  end

  def send_presence_unavailable(pid) do
    GenServer.call(pid, :send_presence_unavailable)
  end

  def available_resources(pid) do
    GenServer.call(pid, :available_resources)
  end

  def full_jid(pid) do
    GenServer.call(pid, :full_jid)
  end

  def resource(pid) do
    GenServer.call(pid, :resource)
  end

  def setup_pubsub(pid, pubsub_service) do
    GenServer.call(pid, {:setup_pubsub, pubsub_service})
  end

  def pubsub_create_node(pid, node_name \\ :resource) do
    GenServer.call(pid, {:pubsub_create_node, node_name})
  end

  def pubsub_ensure_node(pid, node_name \\ :resource) do
    GenServer.call(pid, {:pubsub_ensure_node, node_name})
  end

  def pubsub_publish(pid, xmlel) do
    GenServer.call(pid, {:pubsub_publish, xmlel})
  end

  def pubsub_subscribe(pid, node_name, on_notify) do
    GenServer.call(pid, {:pubsub_subscribe, node_name, on_notify})
  end

  def send_stanza(pid, stanza) do
    GenServer.call(pid, {:send_stanza, stanza})
  end

  # Internals

  def init(args) do
    Process.flag :trap_exit, true
    GenServer.cast(self(), {:connect, args})
    resource = args[:resource]
    {:ok, %State{full_jid: "#{args[:jid]}/#{resource}", resource: resource}}
  end

  def terminate(reason, state) do
    Logger.info "Terminating as #{state.full_jid} because of #{inspect reason}"
    # The unavailable presence is sent automatically
    Conn.close state.conn_pid
  end

  def handle_call(:send_presence_available, _from, state) do
    Conn.send state.conn_pid, Stanza.presence
    {:reply, :ok, state}
  end
  def handle_call(:send_presence_unavailable, _from, state) do
    Conn.send state.conn_pid, Stanza.presence "unavailable"
    {:reply, :ok, state}
  end
  def handle_call(:available_resources, _from, state) do
    {:reply, {:ok, state.available_resources}, state}
  end
  def handle_call(:full_jid, _form, state) do
    {:reply, {:ok, state.full_jid}, state}
  end
  def handle_call(:resource, _form, state) do
    {:reply, {:ok, state.resource}, state}
  end
  def handle_call({:setup_pubsub, pubsub_service}, from, state) do
    Conn.send state.conn_pid, Stanza.disco_info pubsub_service
    {:noreply,
     %{state | pending_request: {:setup_pubsub, from, pubsub_service}}}
  end
  def handle_call({:send_stanza, stanza}, _from, state) do
    {:reply, Conn.send(state.conn_pid, stanza), state}
  end
  def handle_call({:pubsub_create_node, node_name}, from, state) do
    node_name = case node_name do
                  :resource -> state.resource
                  other -> other
                end
    Conn.send state.conn_pid, Stanza.pubsub_create(state.pubsub_service, node_name)
    {:noreply, %{state | pending_request: {:pubsub_create_node, from, node_name}}}
  end
  def handle_call({:pubsub_ensure_node, node_name}, from, state) do
    node_name = case node_name do
                  :resource -> state.resource
                  other -> other
                end
    Conn.send state.conn_pid, Stanza.pubsub_create(state.pubsub_service, node_name)
    {:noreply, %{state | pending_request: {:pubsub_ensure_node, from, node_name}}}
  end
  def handle_call({:pubsub_publish, xmlel}, from, state) do
    Conn.send state.conn_pid, Stanza.pubsub_publish(state.pubsub_service,
      state.resource, xmlel)
    {:noreply,
     %{state | pending_request: {:pubsub_publish, from}}}
  end
  def handle_call({:pubsub_subscribe, node_name, on_notify},
    from, state) do
    Conn.send state.conn_pid, Stanza.pubsub_subscribe(state.pubsub_service,
      node_name, state.full_jid)
    {:noreply,
     %{state |
       pending_request: {:pubsub_subscribe, from, node_name, on_notify}}}
  end

  def handle_cast({:connect, args}, %State{conn_pid: nil} = state) do
    {:ok, pid} = Conn.start_link args
    Logger.info "Conecting as #{state.full_jid}"
    {:noreply, %{state | conn_pid: pid}}
  end

  def handle_info(:connection_ready, %State{conn_ready: false} = state) do
    {:noreply, %{state | conn_ready: true}}
  end
  def handle_info({:stanza, %Presence{from: from, to: to, type: nil}},
    %State{conn_ready: true} = state) when from == to do
    {:noreply, state}
  end
  def handle_info({:stanza, %Presence{from: from, type: nil}},
    %State{conn_ready: true} = state) do
    ar = MapSet.put(state.available_resources, from.full)
    {:noreply, %{state | available_resources: ar}}
  end
  def handle_info({:stanza, %Presence{from: from, type: "unavailable"}},
    %State{conn_ready: true} = state) do
    ar = MapSet.delete(state.available_resources, from.full)
    {:noreply, %{state | available_resources: ar}}
  end
  def handle_info({:stanza, %IQ{type: type, from: %JID{server: pubsub_service}}},
                   %State{pending_request: {:setup_pubsub, pid,
                                            pubsub_service}} = state) do
    case type do
      "error" ->
        GenServer.reply(pid, {:error, :not_available})
      "result" ->
        GenServer.reply(pid, :ok)
    end
    {:noreply, %{state | pending_request: nil, pubsub_service: pubsub_service}}
  end
  def handle_info({:stanza, %IQ{type: type, from: %JID{server: pubsub_service}}},
    %State{pending_request: {:pubsub_create_node, pid, node_name},
           pubsub_service: pubsub_service} = state) do
    case type do
      "error" ->
        GenServer.reply(pid, {:error, :failed_to_create_node})
      "result" ->
        GenServer.reply(pid, :ok)
    end
    {:noreply, %{state | pending_request: nil}}
  end
  def handle_info({:stanza, %IQ{type: type,
                                from: %JID{server: pubsub_service},
                                xml: xml}},
    %State{pending_request: {:pubsub_ensure_node, pid, node_name},
           pubsub_service: pubsub_service} = state) do
    case {type, pubsub_node_conflict?(xml)} do
      {"result", _} ->
        GenServer.reply(pid, :ok)
      {"error", true} ->
        GenServer.reply(pid, :ok)
      {"error", _} ->
        GenServer.reply(pid, {:error, :failed_to_create_node})
    end
    {:noreply, %{state | pending_request: nil}}
  end
  def handle_info({:stanza, %IQ{type: type, from: %JID{server: pubsub_service}}},
    %State{pending_request: {:pubsub_publish, pid},
           pubsub_service: pubsub_service} = state) do
    case type do
      "error" ->
        GenServer.reply(pid, {:error, :failed_to_publish})
      "result" ->
        GenServer.reply(pid, :ok)
    end
    {:noreply, %{state | pending_request: nil}}
  end
  def handle_info({:stanza, %IQ{type: type, from: %JID{server: pubsub_service},
                                xml: xml}},
    %State{pending_request: {:pubsub_subscribe, pid, node_name, on_notify},
           pubsub_service: pubsub_service} = state) do
    sub_id = subscription_id(xml) 
    case type do
      "error" ->
        GenServer.reply(pid, {:error, :failed_to_subscribe})
      "result" ->
        GenServer.reply(pid, {:ok, sub_id})
    end
    if type == "result" do
      sub_id = subscription_id(xml)
      state = %{state | subs: Map.put(state.subs, node_name,
                   fn items -> on_notify.(sub_id, items) end)}
      {:noreply, %{state | pending_request: nil}}
    else
      {:noreply, %{state | pending_request: nil}}
    end
  end
  def handle_info({:stanza, %Message{type: type,
                                     from: %JID{server: pubsub_service},
                                     xml: xml}},
    %State{pubsub_service: pubsub_service} = state) do
    {node_name, items} = pubsub_event_node_and_items(xml)
    (Map.get(state.subs, node_name)).(items)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end


  # Internals

  def pubsub_node_conflict?(iq_xml) do
    case XML.subelement(iq_xml, "error") do
      nil ->
        false
      xmlel ->
        Romeo.XML.subelement(xmlel, "conflict", false) && true
    end
  end

  def subscription_id(iq_xml) do
    iq_xml
    |> XML.subelement("pubsub")
    |> XML.subelement("subscription")
    |> XML.attr("subid")
  end

  def pubsub_event_node_and_items(msg_xml) do
    items =
      msg_xml
      |> XML.subelement("event")
      |> XML.subelement("items")
    {XML.attr(items, "node"), xmlel(items, :children)}
  end

end
