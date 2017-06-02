defmodule UcaLib.Registration do
  @moduledoc """
  This module implements the Registration step from the UDA 2.0
  """

  @type device_jid :: String.t
  @type device_resource :: String.t

  # API

  @doc """
  Connect to the UCS server using the Registration options

  The `opts` overrides the connection options provided in config file under
  the `Registration` key.

  Caller of this function will receive the incoming messages.
  """
  @spec connect(Keyword.t) :: {:ok, pid}
  def connect(opts \\ []) do
    Supervisor.start_child UcaLib.Supervisor, [connect_opts(opts)]
  end

  @doc """
  Disconnect from the UCS
  """
  @spec disconnect(pid) :: {:ok, pid}
  def disconnect(pid), do: Supervisor.terminate_child UcaLib.Supervisor, pid

  @doc """
  Returns a different JID parts of the connection identified by `pid`
  """
  @spec id(pid, type :: :full | :resource) :: {:ok, String.t}
  def id(pid, type \\ :full)
  def id(pid, :full), do: UcaLib.Worker.full_jid pid
  def id(pid, :resource), do: UcaLib.Worker.resource pid

  @doc """
  Returns a resource part of the JID
  """
  @spec resource_from_id(device_jid) :: device_resource
  def resource_from_id(device_jid) do
    String.split(device_jid, "/") |> Enum.at(1)
  end

  # Internals

  defp get_connect_config() do
    Application.get_env :uca_lib, Registration
  end

  defp connect_opts(opts) do
    config = get_connect_config()
    Keyword.merge [{:resource, resource(config)} | config], opts
  end

  # TODO: Appropriately form an XMPP resource
  # See C.5.4 Binding Devices and Control Points as a Resource in UDA 2.0
  defp resource(config) do
    device_type = config[:device_type]
    device_version = config[:device_version]
    "urn:schemas-upnp-org:device:#{device_type}:#{device_version}:#{uuid()}"
  end

  defp uuid(), do: UUID.uuid4()
end
