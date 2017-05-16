defmodule SampleApp.UccCp do
  use GenServer
  alias UcaLib.{Registration, Discovery}
  alias SampleApp.UccCp.Device

  @refresh_timeout 1_000

  @type device_id :: String.t
  @type subscription :: Subscription.t
  @type subscription_ref :: reference

  defmodule Subscription do
    @type t :: %__MODULE__{
      device_activated: ((Device.t) -> term),
      device_deactivated: ((Device.t) -> term)
    }
    defstruct [:device_activated, :device_deactivated]
  end

  defmodule State do
    defstruct devices: [],
      conn_pid: nil,
      current_device: nil,
      disco_ref: nil,
      subscriptions: %{}
  end

  # API

  @spec start_link() :: {:ok, pid}
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
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

  @spec subscribe(subscription) :: {:ok, subscription_ref} | {:error, term}
  def subscribe(subscription) do
    GenServer.call(__MODULE__, {:subcribe, subscription})
  end

  @spec unsubscribe(subscription_ref) :: :ok | {:error, term}
  def unsubscribe(ref) do
    GenServer.call(__MODULE__, {:unsubscribe, ref})
  end


  # Callbacks

  def init(opts) do
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
  def handle_call(
    {:subcribe, %Subscription{device_activated: sub_fun,
                              device_deactivated: unsub_fun} = sub},
    _from,
    %State{subscriptions: subs} = state)
  when is_function(sub_fun, 1) and is_function(unsub_fun, 1) do
    ref = make_ref()
    {:reply, {:ok, ref}, %{state | subscriptions: Map.put(subs, ref, sub)}}
  end
  def handle_call({:subcribe, _}, _from, state) do
    {:reply, {:error, :bad_subscription}, state}
  end
  def handle_call({:unsubscribe, ref}, _from, state) do
    case Map.pop(state.subscriptions, ref) do
      {nil, _} -> {:reply, {:error, :bad_ref}, state}
      {_sub, subs} -> {:reply, :ok, %{state | subscriptions: subs}}
    end
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
    devices
    |> devices_diff(state.devices)
    |> broadcast_devices_diff(state.subscriptions)
    schedule_devices_list_refresh(@refresh_timeout)
    {:noreply, %{state | devices: devices}}
  end

  # Internals

  defp schedule_devices_list_refresh(timeout_ms) do
    Process.send_after(self(), :refresh_devices, timeout_ms)
  end

  defp devices_diff(new_devices, old_devices) do
    activated = new_devices -- old_devices
    deactivated = old_devices -- new_devices
    {activated, deactivated}
  end

  defp broadcast_devices_diff({activated, deactivated}, subscriptions) do
    activated |> Enum.each(&broadcast_activated(&1, subscriptions))
    deactivated |> Enum.each(&broadcast_deactivated(&1, subscriptions))
  end

  defp broadcast_activated(device, subscriptions) do
    Enum.each(subscriptions,
      fn({_ref, %Subscription{device_activated: fun}}) -> fun.(device) end)
  end

  defp broadcast_deactivated(device, subscriptions) do
    Enum.each(subscriptions,
      fn({_ref, %Subscription{device_deactivated: fun}}) -> fun.(device) end)
  end

end
