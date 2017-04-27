defmodule NervesUccd.Worker do
  use GenServer
  alias Nerves.Networking

  def start_link() do
    {:ok, _pid} = Networking.setup :eth0
  end
end
