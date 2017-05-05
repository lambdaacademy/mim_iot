defmodule NervesUccd.Networking do

  def setup() do
    type = Application.get_env(:nerves_uccd, Networking)[:type]
    opts = Application.get_env(:nerves_uccd, Networking)[:opts]
    setup type, opts
  end

  defp setup(:none, _), do: :ok
  defp setup(:eth, opts) do
    {:ok, _} = Nerves.Networking.setup opts[:interface]
  end
  defp setup(:wireless, opts) do
    {_, 0} = System.cmd("modprobe", ["brcmfmac"])
    {:ok, _} = Nerves.InterimWiFi.setup opts[:interface],
      Keyword.delete(opts, :interface)
  end
end
