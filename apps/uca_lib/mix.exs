defmodule UcaLib.Mixfile do
  use Mix.Project

  def project do
    [app: :uca_lib,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [mod: {UcaLib.Application, []},
     extra_applications: [:logger]]
  end

  defp deps do
    [{:romeo, github: "mentels/romeo"},
     {:uuid, "~> 1.1"},
     {:fsm, "~> 0.3"}]
  end
end
