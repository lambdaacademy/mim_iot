defmodule NervesUccd.Networking do

  @config Application.get_env(:nerves_uccd, Networking)
  @net_type @config[:type]
  @net_mode @config[:mode]
  @net_opts @config[:opts]

  @dhcp_check_interval 2_000
  @dhcp_timeout 10_000

  # API

  def setup() do
    setup @net_type, @net_mode, @net_opts
  end

  # Internals

  defp setup(nil, _, _), do: :ok
  defp setup(:ethernet, mode, opts) do
    {:ok, _} = Nerves.Networking.setup opts[:interface], eth_opts(mode, opts)
    case mode do
      :static -> :ok
      :dynamic -> wait_for_dhcp_bind(opts)
    end
  end
  defp setup(:wireless, mode, opts) do
    {_, 0} = System.cmd("modprobe", ["brcmfmac"])
    {:ok, _} = Nerves.InterimWiFi.setup opts[:interface],
      Keyword.delete(opts, :interface)
  end

  defp eth_opts(:dynamic, _), do: []
  defp eth_opts(:static, opts),
    do: [mode: "static", ip: opts[:ip], mask: opts[:mask]]

  defp wait_for_dhcp_bind(opts) do
    respond_to = self()
    dhcp_wait_fun = fn interface, rec_fun ->
      Process.sleep(@dhcp_check_interval)
      if (Nerves.Networking.settings(interface)).status == "bound" do
        send(respond_to, {self(), :dhcp_bound})
      else
        rec_fun.(interface, rec_fun)
      end
    end
    pid = spawn_link(fn -> dhcp_wait_fun.(opts[:interface], dhcp_wait_fun) end)
    receive do
      {^pid, :dhcp_bound} -> :ok
    after @dhcp_timeout -> {:error, :dhcp_failed}
    end
  end


end
