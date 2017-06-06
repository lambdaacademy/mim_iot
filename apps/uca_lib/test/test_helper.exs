ExUnit.start()

defmodule UcaLib.ConnFsmBackend do
  def start_link(args) do
    <<a, b>> = :crypto.strong_rand_bytes(2)
    {:ok, pid_from_string("<0.#{a}.#{b}>")}
  end

  def close(pid) when is_pid(pid), do: :ok

  def send(pid, stanza) when is_pid(pid), do: :ok

  defp pid_from_string(string) do
    string
    |> :erlang.binary_to_list
    |> :erlang.list_to_pid
  end
end
