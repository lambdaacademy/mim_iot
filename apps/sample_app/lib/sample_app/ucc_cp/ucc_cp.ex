defmodule SampleApp.UccCp do
  use GenServer
  alias UcaLib.{Registration, Discovery}
  alias SampleApp.UccCp.Device

  @refresh_timeout 1_000

  @type device_id :: String.t

  defmodule State do
    defstruct devices: [], conn_pid: nil, current_device: nil, disco_ref: nil
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
  @spec devices() :: {:ok, [Device.t]} | {:ok, :not_connected}
  def devices() do
    GenServer.call(__MODULE__, :devices)
  end

  @doc """
  Return a device identified by `device_id`
  """
  @spec device(device_id) :: {:ok, Device.t} | {:ok, :not_connected}
  | {:error, :no_device}
  def device(device_id) do
    GenServer.call(__MODULE__, {:device, device_id})
  end

  @spec current_device() :: {:ok, Device.t}
  def current_device() do
    GenServer.call(__MODULE__, :current_device)
  end


  # Callbacks

  def init(_) do
    opts = []
    GenServer.cast(self(), {:connect, opts})
    {:ok, %State{}}
  end

  def terminate(_reason, state) do
    UcaLib.Registration.disconnect state.conn_pid
  end

  def handle_call(_, _, %State{conn_pid: nil} = state) do
    {:reply, {:ok, :not_connected}, state}
  end
  def handle_call(:devices, _from, state) do
    {:reply, {:ok, state.devices}, state}
  end
  def handle_call(:current_device, _from, state) do
    {:reply, {:ok, state.current_device}, state}
  end
  def handle_call({:device, device_id}, _from, state) do
    reply = case Enum.find(state.devices, &(&1.device_id == device_id)) do
      nil -> {:error, :no_device}
      device -> {:ok, device}
    end
    {:reply, reply, state}
  end

  def handle_cast({:connect, opts}, state) do
    {:ok, pid} = Registration.connect(opts)
    {:ok, current_device} = Registration.id(pid)
    :ok = Discovery.activate(pid)
    ref = schedule_devices_list_refresh(@refresh_timeout)
    {:noreply,
     %{state | conn_pid: pid, current_device: current_device, disco_ref: ref}}
  end

  def handle_info(:refresh_devices, state) do
    {:ok, devices} = Discovery.devices(state.conn_pid)
    devices = for d <- devices, do: %Device{device_id: d}
    schedule_devices_list_refresh(@refresh_timeout)
    {:noreply, %{state | devices: devices}}
  end

  # Internals

  def schedule_devices_list_refresh(timeout_ms) do
    Process.send_after(self(), :refresh_devices, timeout_ms)
  end

end
