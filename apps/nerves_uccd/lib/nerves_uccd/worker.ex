defmodule NervesUccd.Worker do
  use GenServer

  alias NervesUccd.{Networking}
  alias UcaLib.{Discovery, Registration}

  @name __MODULE__

  require Logger

  def start_link(), do: GenServer.start_link(__MODULE__, nil, [name: @name])

  def init(_) do
    GenServer.cast(@name, :setup_networking)
    {:ok, nil}
  end

  def handle_cast(:setup_networking, state) do
    :ok = Networking.setup
    GenServer.cast(@name, :setup_uca)
    {:noreply, state}
  end

  def handle_cast(:setup_uca, state) do
    {:ok, pid} = Registration.connect
    :ok = Discovery.activate pid
    {:noreply, state}
  end

end
