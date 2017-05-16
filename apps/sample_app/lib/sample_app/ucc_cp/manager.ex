defmodule SampleApp.UccCp.Manager do
  use GenServer
  alias SampleApp.Web.{Endpoint, Router}
  alias SampleApp.{UccCp, UccCp.Subscription, UccCp.Device}

  @listing_topic "devices:listing"

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    GenServer.cast(self(), :subscribe)
    {:ok, nil}
  end

  def handle_cast(:subscribe, _) do
    {:ok, ref} = UccCp.subscribe(subscription())
    {:noreply, ref}
  end

  defp subscription() do
    %Subscription{device_activated: &on_activate/1,
                  device_deactivated: &on_deactivate/1}
  end

  defp on_activate(%Device{} = d) do
    device_url = Router.Helpers.device_url Endpoint, :show, d.device_id, %{}
    params = Map.from_struct(d) |> Map.put(:url, device_url)
    Endpoint.broadcast! @listing_topic, "activated", params
  end

  defp on_deactivate(%Device{} = d) do
    Endpoint.broadcast! @listing_topic, "deactivated", Map.from_struct(d)
  end
end
