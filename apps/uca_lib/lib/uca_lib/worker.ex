defmodule UcaLib.Worker do
  use GenServer
  require Logger

  alias Romeo.Connection, as: Conn
  alias Romeo.Stanza
  alias Romeo.Stanza.Presence

  defmodule State do
    defstruct conn_pid: nil,
      conn_ready: false,
      available_resources: MapSet.new,
      full_jid: nil,
      resource: nil
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
  def handle_call({:send_stanza, stanza}, _from , state) do
    {:reply, Conn.send(state.conn_pid, stanza), state}
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
  def handle_info(_msg, state) do
    {:noreply, state}
  end
  
end
