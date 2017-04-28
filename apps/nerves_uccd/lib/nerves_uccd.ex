defmodule NervesUccd do
  alias Nerves.Networking

  @interface :eth0

  def setup_networking() do
    # don't start networking unless we're on nerves
    unless :os.type == {:unix, :darwin} do
      {:ok, _} = Networking.setup @interface
    end
  end

end
