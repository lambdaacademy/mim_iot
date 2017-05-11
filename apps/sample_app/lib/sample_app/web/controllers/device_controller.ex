defmodule SampleApp.Web.DeviceController do
  use SampleApp.Web, :controller

  def index(conn, _params) do
    {:ok, devs} = SampleApp.UccCp.devices
    render conn, "index.html", devices: devs
  end
end
