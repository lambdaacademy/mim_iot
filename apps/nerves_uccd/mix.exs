defmodule NervesUccd.Mixfile do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"
  Mix.shell.info([:green, """
  Env
    MIX_TARGET:   #{@target}
    MIX_ENV:      #{Mix.env}
  """, :reset])
  def project do
    [app: :nerves_uccd,
     version: "0.1.0",
     elixir: "~> 1.4.0",
     target: @target,
     archives: [nerves_bootstrap: "~> 0.3.0"],
     deps_path: "../../deps/#{@target}",
     build_path: "../../_build/#{@target}",
     config_path: "config/config.exs",
     lockfile: "../../mix.lock",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(@target),
     deps: deps()]
  end

  def application, do: application(@target)

  # Specify target specific application configurations
  # It is common that the application start function will start and supervise
  # applications which could cause the host to fail. Because of this, we only
  # invoke NervesUccd.start/2 when running on a target.
  def application("host") do
    [extra_applications: [:logger]]
  end
  def application(_target) do
    [mod: {NervesUccd.Application, []},
     extra_applications: [:logger, :ssl]]
  end

  def deps do
    [{:nerves, "~> 0.5.0", runtime: false},
     {:romeo, github: "mentels/romeo"},
     {:uca_lib, in_umbrella: true}] ++
    deps(@target)
  end

  def deps("host"), do: []
  def deps("mim_iot_rpi") do
    mim_iot_deps() ++ [
      {:mim_iot_rpi, "0.12.0-dev", github: "mentels/mim_iot_rpi", runtime: false}]
      # path: "~/proj/iot/nerves_rpi_builder/mim_iot_rpi", runtime: false}]
  end
  def deps("mim_iot_rpi0") do
    mim_iot_deps() ++ [
     {:mim_iot_rpi0, "0.13.0-dev", github: "mentels/mim_iot_rpi0", runtime: false}]
      # path: "~/proj/iot/nerves_rpi_builder/mim_iot_rpi0", runtime: false}]
  end
  def deps("mim_iot_rpi3") do
    mim_iot_deps() ++ [
     {:mim_iot_rpi3, "0.13.0-dev", github: "mentels/mim_iot_rpi3", runtime: false}]
    # path: "~/proj/iot/nerves_rpi_builder/mim_iot_rpi3", runtime: false}]
  end
  def deps(target) do
    [{:nerves_runtime, "~> 0.1.0"},
     {:"nerves_system_#{target}", "~> 0.11.0", runtime: false}]
  end

  defp mim_iot_deps() do
    [{:nerves_runtime, "~> 0.1.0"},
     {:nerves_interim_wifi, "~> 0.2"},
     {:nerves_networking, "~> 0.6"},
     {:erl_sshd, github: "ivanos/erl_sshd"}]
  end

  # We do not invoke the Nerves Env when running on the Host
  def aliases("host"), do: []
  def aliases(_target) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end
end
