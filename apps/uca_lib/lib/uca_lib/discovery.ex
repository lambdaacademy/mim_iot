defmodule UcaLib.Discovery do
  @moduledoc """
  This module implements the Discovery step from the UDA 2.0
  """
  alias UcaLib.Worker

  @doc """
  Report readiness to participate in UCA
  """
  @spec activate(pid) :: :ok
  def activate(pid) do
    Worker.send_presence_available pid
  end

  @doc """
  Cancel readiness to participate in UCA
  """
  @spec deactivate(pid) :: :ok
  def deactivate(pid) do
    Worker.send_presence_unavailable pid
  end

  @doc """
  Return the list of the discovered devices

  """
  @spec devices(pid) :: {:ok, [String.t]}
  def devices(pid) do
    Worker.presences_available pid
  end

end
