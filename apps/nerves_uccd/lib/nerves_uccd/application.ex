defmodule NervesUccd.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [worker(NervesUccd.Worker, [])]

    opts = [strategy: :one_for_one, name: NervesUccd.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
