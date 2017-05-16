defmodule SampleApp.Web.DevicesChannel do
  use SampleApp.Web, :channel
  alias SampleApp.{Web.Endpoint, UccCp, UccCp.Subscription, UccCp.Device}

  @listing_topic "devices:listing"

  def join(@listing_topic, payload, socket) do
    {:ok, socket}
  end

  def terminate(_msg, socket) do
    :ok
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

end
