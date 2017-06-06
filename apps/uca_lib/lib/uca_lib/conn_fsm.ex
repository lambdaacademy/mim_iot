defmodule UcaLib.ConnFsm do
  use Fsm, initial_state: :disconnected

  defmodule Data do
    defstruct conn_backend: Romeo.Connection,
      conn_pid: nil,
      conn_timeout_ref: nil,
      trans: %{}
  end

  alias Romeo.Stanza
  alias Romeo.Stanza.{Presence, IQ, Message}

  @conn_timeout 10_000

  # FSM API

  defevent send_message/1

  defstate :disconnected do
    # only for testing purposes
    defevent set_conn_backend(backend) do
      next_state(:disconnected, %Data{conn_backend: backend})
    end
    defevent connect(args), data: data do
      data = _init_data(data)
      {:ok, pid} = _connect(args, data.conn_backend)
      ref = _set_conn_timeout(self(), @conn_timeout)
      next_state(:waiting_for_conn,
        %{data | conn_pid: pid, conn_timeout_ref: ref})
    end
  end

  defstate :waiting_for_conn do
    defevent conn_timeout(), data: data do
      _disconnect(data.conn_pid, data.conn_backend)
      next_state(:disconnected, %{data | conn_pid: nil, conn_timeout_ref: nil})
    end
    defevent conn_ready(), data: data do
      _cancel_conn_timeout(data.conn_timeout_ref)
      next_state(:connected, %{data | conn_timeout_ref: nil})
    end
    defevent _, do: respond({:error, :not_connected})
  end

  defstate :connected do
    defevent send_initial_presence(on_confirmation), data: data do
      :ok = _send_presence(data.conn_pid, data.conn_backend, :available)
      next_state(:connected,
        %{data | trans: add_transaction(data.trans, :presence, on_confirmation)})
    end
    defevent handle_stanza(%Presence{from: from, to: from}), data: data do
      reply = :ok
      next_state(:available,
        %{data | trans: close_transaction(data.trans, :presence, reply)})
    end
    defevent handle_stanza(stanza), do: respond(:ignored)
    defevent _, do: respond({:error, :unavailable})
  end

  defstate :available do
    defevent send_presence_unavailable(), data: data do
      :ok = _send_presence(data.conn_pid, data.conn_backend, :available)
      next_state(:connected)
    end
  end

  # Internals: XMPP

  @spec _send_presence(pid, module, :available | :unavailable) :: :ok
  defp _send_presence(pid, backend, type) when type == :available,
    do: _send(pid, backend, Stanza.presence())
  defp _send_presence(pid, backend, type) when type == :unavailable,
    do: _send(pid, backend, Stanza.presence(type: "unavailable"))

  # Internals: Connection

  defp _init_data(nil), do: %Data{}
  defp _init_data(%Data{} = data), do: data

  @spec _connect(Keyword.t, module) :: {:ok, pid}
  defp _connect(args, backend) do
    backend.start_link(args)
  end

  @spec _disconnect(pid, module) :: :ok
  defp _disconnect(pid, backend) do
    backend.close(pid)
    Process.exit(pid, :kill)
  end

  @spec _send(pid, module, term) :: :ok
  defp _send(pid, backend, stanza) do
    backend.send(pid, stanza)
  end

  @spec _set_conn_timeout(pid, non_neg_integer) :: reference
  defp _set_conn_timeout(send_to, timeout) do
    Process.send_after(send_to, :connection_timeout, timeout)
  end

  @spec _cancel_conn_timeout(reference) :: :ok
  defp _cancel_conn_timeout(ref) do
    Process.cancel_timer(ref)
    :ok
  end

  @spec add_transaction(map, term, ((result :: term) -> term)) :: map
  defp add_transaction(transactions, id, on_completion)
  when is_function(on_completion, 1), do: Map.put(transactions, id, on_completion) 

  @spec close_transaction(map, term, term) :: map
  defp close_transaction(transactions, id, reply) do
    {on_completion, transactions} = Map.pop(transactions, id)
    on_completion.(reply)
    transactions
  end

end
