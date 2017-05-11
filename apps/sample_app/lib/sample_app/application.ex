defmodule SampleApp.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(SampleApp.Web.Endpoint, []),
      worker(SampleApp.UccCp, []),
    ]

    opts = [strategy: :one_for_one, name: SampleApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
