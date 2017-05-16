defmodule SampleApp.Web.Router do
  use SampleApp.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SampleApp.Web do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/devices", DeviceController, only: [:index, :show]

  end

end
