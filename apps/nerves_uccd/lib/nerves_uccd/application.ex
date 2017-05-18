defmodule NervesUccd.Application do
  use Application

  alias UcaLib.{Discovery, Registration}

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = []

    NervesUccd.Networking.setup
    connect()

    opts = [strategy: :one_for_one, name: NervesUccd.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp connect() do
    {:ok, pid} = Registration.connect
    Discovery.activate pid
  end

end
