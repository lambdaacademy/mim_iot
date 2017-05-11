defmodule SampleApp.UccCp do
  use GenServer
  alias UcaLib.{Registration, Discovery}

  @refresh_timeout 1_000

  @type device_id :: String.t

  defmodule State do
    defstruct devices: [], conn_pid: nil, disco_ref: nil
  end

  # API

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Return this device id.
  """
  @spec device_id() :: {:ok, device_id}
  def device_id() do
    GenServer.call(__MODULE__, :device_id)
  end

  @doc """
  Return a list of devices discovered by this control point
  """
  @spec devices() :: {:ok, [device_id]} | {:ok, :not_connected}
  def devices() do
    GenServer.call(__MODULE__, :devices)
  end

  # Callbacks

  def init(_) do
    opts = []
    GenServer.cast(self(), {:connect, opts})
    {:ok, %State{}}
  end

  def terminate(reason, state) do
    UcaLib.Registration.disconnect state.conn_pid
  end

  def handle_call(_, _, %State{conn_pid: nil} = state) do
    {:reply, {:ok, :not_connected}, state}
  end
  def handle_call(:devices, _from, state) do
    {:reply, {:ok, state.devices}, state}
  end

  def handle_cast({:connect, opts}, state) do
    {:ok, pid} = Registration.connect(opts)
    :ok = Discovery.activate(pid)
    ref = schedule_devices_list_refresh(@refresh_timeout)
    {:noreply, %{state | conn_pid: pid, disco_ref: ref}}
  end

  def handle_info(:refresh_devices, state) do
    {:ok, devices} = Discovery.devices(state.conn_pid)
    schedule_devices_list_refresh(@refresh_timeout)
    {:noreply, %{state | devices: devices}}
  end

  # Internals

  def schedule_devices_list_refresh(timeout_ms) do
    Process.send_after(self(), :refresh_devices, timeout_ms)
  end

end
