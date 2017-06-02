defmodule NervesUccd.Networking do
  use GenServer
  require Logger

  # API

  def start_link(worker) do
    GenServer.start_link(__MODULE__, worker, name: __MODULE__)
  end

  # Callbacks

  def init(worker) do
    send(self(), :setup)
    {:ok, %{worker: worker}}
  end

  def handle_info(:setup, state) do
    config = Application.get_env(:nerves_uccd, Networking)
    setup(config[:type], config[:opts])
    {:noreply, state}
  end
  def handle_info({Nerves.NetworkInterface, _, %{is_running: true, is_up: true}}, state) do
    send state.worker, :setup_uca
    {:noreply, state}
  end
  def handle_info({Nerves.Udhcpc, event, %{ipv4_address: ip}}, state) when event in [:bound, :renew] do
    Logger.info "IP Address #{inspect ip}"
    send state.worker, :setup_uca
    {:noreply, state}
  end
  def handle_info(message, state) do
    Logger.info inspect(message)
    {:noreply, state}
  end

  # Internals

  defp setup(nil, _), do: :ok
  defp setup(:ethernet, opts) do
    interface = to_string(opts[:interface])

    case Keyword.fetch(opts, :ip) do
      {:ok, ip} -> setup_static_interface(interface, ip)
      :error    -> setup_dynamic_interface(interface)
    end
  end
  defp setup(:wireless, opts) do
    interface = to_string(opts[:interface])
    {_, 0} = System.cmd("modprobe", ["brcmfmac"])
    setup_dynamic_interface(interface, Keyword.delete(opts, :interface))
  end

  defp setup_static_interface(interface, ip) do
    :ok = Nerves.NetworkInterface.ifdown interface
    {:ok, _} = Registry.register(Nerves.NetworkInterface, interface, [])
    :ok = Nerves.NetworkInterface.setup interface, ipv4_address: ip
    :ok = Nerves.NetworkInterface.ifup interface
  end

  defp setup_dynamic_interface(interface, opts \\ []) do
    {:ok, _} = Registry.register(Nerves.Udhcpc, interface, [])
    {:ok, _} = Nerves.InterimWiFi.setup interface, opts
  end
end
