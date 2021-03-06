defmodule SampleApp.Web.DeviceController do
  use SampleApp.Web, :controller

  def index(conn, _params) do
    {:ok, devs} = SampleApp.UccCp.devices
    {:ok, dev} = SampleApp.UccCp.current_device
    render conn, "index.html", devices: devs, current_device: dev
  end

  def show(conn, %{"id" => device_id}) do
    {:ok, dev} = SampleApp.UccCp.device device_id
    render conn, "show.html", device: dev
  end
end
