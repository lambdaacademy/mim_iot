defmodule UcaLib.Worker do
  use GenServer
  require Logger

  alias Romeo.Connection, as: Conn
  alias Romeo.Stanza

  defmodule State do
    defstruct conn_pid: nil
  end

  # API

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def send_presence_available(pid) do
    GenServer.call(pid, :send_presence_available)
  end

  def send_presence_unavailable(pid) do
    GenServer.call(pid, :send_presence_unavailable)
  end

  # Internals

  def init(args) do
    Process.flag :trap_exit, true
    {:ok, pid} = Conn.start_link args
    Logger.info "Conected to: #{inspect args[:host]} as: #{inspect args[:jid]}"
    GenServer.cast(self(), :wait_for_conn)
    {:ok,  %State{conn_pid: pid}}
  end

  def terminate(reason, state) do
    Logger.info "Terminating connection because of #{inspect reason}"
    # The unavailable presence is sent automatically
    Conn.close state.conn_pid
  end

  def handle_call(:send_presence_available, _from, state) do
    Conn.send state.conn_pid, Stanza.presence
    receive do
      {:stanza, %Stanza.Presence{}} -> {:reply, :ok, state}
    after
      4000 ->
        Logger.error "Presence not confirmed"
        {:stop, :presence_not_confirmed, {:error, :presence_not_confirmed}, state}
    end
  end
  def handle_call(:send_presence_unavailable, _from, state) do
    Conn.send state.conn_pid, Stanza.presence "unavailable"
    {:reply, :ok, state}
  end

  def handle_cast(:wait_for_conn, state) do
    receive do
      :connection_ready -> {:noreply, state}
    after 
      5000 -> {:stop, :server_not_responding, state}
    end
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
  
end
