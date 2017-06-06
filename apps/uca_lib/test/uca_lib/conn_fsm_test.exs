defmodule UcaLib.ConnFsmTest do
  use ExUnit.Case

  alias UcaLib.ConnFsm
  alias UcaLib.ConnFsmBackend, as: MockBackend

  alias Romeo.Stanza.{IQ, Presence, Message}

  setup_all do
    {:ok, %{bare_jid: "ala@krakow.pl", resource: "res1"}}
  end

  test "initial state is :disconnected" do
    assert ConnFsm.new().state() == :disconnected
  end

  test ":disconnected transitions to :waiting_for_conn on :connect" do
    fsm = fsm_with_mock_backend() |> ConnFsm.connect([])
    assert fsm.state == :waiting_for_conn
  end

  test ":waiting_for_conn transitions to :disconnected on :conn_timeout" do
    fsm = fsm_with_mock_backend() |> ConnFsm.connect([]) |> ConnFsm.conn_timeout()
    assert fsm.state == :disconnected
  end

  test ":waiting_for_conn transitions to :conected on :conn_ready" do
    fsm = fsm_with_mock_backend() |> ConnFsm.connect([]) |> ConnFsm.conn_ready()
    assert fsm.state == :connected
  end

  test "responds with an error in :waiting_for_conn on attempt to send " <>
    "an initial presence" do
    # GIVEN
    fsm = fsm_with_mock_backend()

    # WHEN
    {reply, fsm} =
      fsm
      |> ConnFsm.connect([])
      |> ConnFsm.send_initial_presence(&(&1))

    # THEN
    assert reply == {:error, :not_connected}
    assert fsm.state == :waiting_for_conn
  end

  test "after sending initial presence stays in :connected" do
    # GIVEN
    fsm = fsm_with_mock_backend()
    self = self()
    on_confirmation = fn reply -> send(self, reply) end 

    # WHEN
    fsm =
      fsm
      |> ConnFsm.connect([])
      |> ConnFsm.conn_ready()
      |> ConnFsm.send_initial_presence(on_confirmation)
    assert fsm.state == :connected
  end

  test "before confirmation of the initial presence ignores incoming stanzas" do
    # GIVEN
    fsm = fsm_with_mock_backend()
    self = self()
    on_confirmation = fn reply -> send(self, reply) end 

    # WHEN
    {reply, fsm} =
      fsm
      |> ConnFsm.connect([])
      |> ConnFsm.conn_ready()
      |> ConnFsm.send_initial_presence(on_confirmation)
      |> ConnFsm.handle_stanza(%IQ{})

    # THEN
    assert fsm.state == :connected
    assert reply == :ignored
    refute_receive :ok
  end

  test "responds with an error in :connected on attempt to send stanza" do
    # GIVEN
    fsm = fsm_with_mock_backend()
    self = self()
    on_confirmation = fn reply -> send(self, reply) end 

    # WHEN
    {reply, fsm} =
      fsm
      |> ConnFsm.connect([])
      |> ConnFsm.conn_ready()
      |> ConnFsm.send_initial_presence(on_confirmation)
      |> ConnFsm.send_message(%Message{})

    # THEN
    assert reply == {:error, :unavailable}
    assert fsm.state == :connected
    refute_receive :ok
  end

  test ":connected transitions to available on confirmation of " <>
    " the initial presence", %{bare_jid: jid, resource: res} do
    # GIVEN
    full_jid = full_jid(jid, res)
    self = self()
    on_confirmation = fn reply -> send(self, reply) end 
    fsm = fsm_with_mock_backend()

    # WHEN
    fsm =
      fsm
      |> ConnFsm.connect([])
      |> ConnFsm.conn_ready()
      |> ConnFsm.send_initial_presence(on_confirmation)
      |> ConnFsm.handle_stanza(%Presence{from: full_jid, to: full_jid})

    # THEN
    assert fsm.state == :available
    assert_receive :ok
  end


  test ":available transitions to connected on sending presence unavailable",
    %{bare_jid: jid, resource: res} do
    # GIVEN
    full_jid = full_jid(jid, res)
    self = self()
    on_confirmation = fn reply -> send(self, reply) end 
    fsm = fsm_with_mock_backend()

    # WHEN
    fsm =
      fsm
      |> ConnFsm.connect([])
      |> ConnFsm.conn_ready()
      |> ConnFsm.send_initial_presence(on_confirmation)
      |> ConnFsm.handle_stanza(%Presence{from: full_jid, to: full_jid})
      |> ConnFsm.send_presence_unavailable()

    # THEN
    assert fsm.state == :connected
  end

  # Helpers

  defp fsm_with_mock_backend() do
    ConnFsm.new() |> ConnFsm.set_conn_backend(MockBackend)
  end

  defp full_jid(bare_jid, resource), do: "#{bare_jid}/#{resource}"
end
