defmodule UcaLib.Eventing do
  @moduldoc """
  Provides functionality required for UPnP+ Eventing step.

  ## Examples:

      alias UcaLib.Eventing
      subitem = Eventing.xml_node("subitem", [], [Eventing.xml_node_content("hello")])
      item = Eventing.xml_node("item", [{"id", "12345"}],[subitem])

  The aforementioned example corresponds to the folowing XML:

      <item id='12345'><subitem>hello</subitem></item>

  """
  use Romeo.XML
  alias UcaLib.{Worker, Registration}

  @type sub_id :: String.t
  @type on_notify :: ((sub_id, xmlel :: tuple) -> term)

  @pubsub_service Application.get_env(:uca_lib, Eventing)[:pubsub] ||
    "pubsub.localhost"

  @doc """
  Setups eventing for a device.

  If the `create_node` option is set to to a truthy value, it will create
  a pubsub node named after the XMPP resource. The `create_node`
  defaults to `true.`
  """
  @spec setup(pid, Keyword.t) :: :ok | {:error, term}
  def setup(pid, opts \\ []) do
    case Worker.setup_pubsub pid, @pubsub_service do
      {:error, _} = e -> e
      :ok -> opts[:create_node] && Worker.pubsub_ensure_node pid
    end
  end

  @doc """
  Publishes an item on the device pubsub node.

  The `xmlel` is an xmlel record defined in `Romeo.XML`.
  """
  @spec publish(pid, xmlel :: tuple) :: :ok | {:error, term}
  def publish(pid, xmlel) do
    Worker.pubsub_publish pid, xmlel
  end

  @doc """
  Subscribes to a pubsub node of a device.
  """
  @spec subscribe(pid, Registration.device_jid, on_notify)
    :: {:ok, sub_id} | {:error, term}
  def subscribe(pid, device_jid, on_notify) do
      Worker.pubsub_subscribe pid, Registration.resource_from_id(device_jid),
        on_notify
  end

  @doc """
  Generates an xmlel record.
  """
  def xml_node(name, attrs, children) do
    xmlel(name: name, attrs: attrs, children: children)
  end

  @doc """
  Generates an xmlcdata record.
  """
  def xml_node_content(content), do: xmlcdata(content: content)

end
