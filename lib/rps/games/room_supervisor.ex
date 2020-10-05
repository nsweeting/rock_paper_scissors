defmodule RPS.Games.RoomSupervisor do
  @moduledoc """
  A supervisor of game rooms.
  """

  use DynamicSupervisor

  alias RPS.Games.Room

  ################################
  # Public API
  ################################

  @doc """
  Starts the room supervisor process.
  """
  @spec start_link(any) :: Supervisor.on_start()
  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Starts a new room under the supervisor.
  """
  @spec start(RPS.Accounts.User.t()) :: DynamicSupervisor.on_start_child()
  def start(user) do
    spec = {Room, {user, self()}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  ################################
  # DynamicSupervisor Callbacks
  ################################

  @impl DynamicSupervisor
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
