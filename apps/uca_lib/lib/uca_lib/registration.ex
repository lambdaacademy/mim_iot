defmodule UcaLib.Registration do
  @moduledoc """
  This module implements the Registration step from the UDA 2.0
  """

  @connect_config Application.get_env :uca_lib, Registration

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

  # Internals

  defp connect_opts(opts) do
    Keyword.merge [{:resource, resource()} | @connect_config], opts
  end

  # TODO: Appropriately form an XMPP resource
  # See C.5.4 Binding Devices and Control Points as a Resource in UDA 2.0
  defp resource() do
    "res"
  end

end
