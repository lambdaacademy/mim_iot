defmodule UcaLib.Application do
  use Application

  import Supervisor.Spec

  def start(_type, _args) do
    worker = worker(UcaLib.Worker, [], restart: :transient)
    Supervisor.start_link([worker], strategy: :simple_one_for_one,
      name: UcaLib.Supervisor)
  end
end
