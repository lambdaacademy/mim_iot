defmodule SampleApp.Application do
  use Application
  alias SampleApp.UccCp
  alias SampleApp.Web

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Web.Endpoint, []),
      ucc_cp_supervisor()
    ]

    opts = [strategy: :one_for_one, name: SampleApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Internals

  defp ucc_cp_supervisor() do
    import Supervisor.Spec
    children = [
      worker(UccCp, []),
      worker(UccCp.Manager, [])
    ]
    opts = [id: UccCp.Supervisor, strategy: :one_for_all]
    supervisor(Supervisor, [children, opts])
  end

end

