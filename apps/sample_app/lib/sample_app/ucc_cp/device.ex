defmodule SampleApp.UccCp.Device do
  use Ecto.Schema

  @derive {Phoenix.Param, key: :device_id}
  embedded_schema do
    field :device_id, :string
  end
end
