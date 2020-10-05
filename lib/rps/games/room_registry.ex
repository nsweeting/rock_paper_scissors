defmodule RPS.Games.RoomRegistry do
  @moduledoc """
  A registry of available game rooms.
  """

  ################################
  # Public API
  ################################

  @spec child_spec(any()) :: Supervisor.child_spec()
  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  @doc """
  Starts the room registry process.
  """
  @spec start_link :: GenServer.on_start()
  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  @doc """
  Registers a users game room as available.
  """
  @spec register(RPS.Accounts.User.t()) :: :ok | {:error, :already_registered}
  def register(user) do
    case Registry.register(__MODULE__, user.id, user.username) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :already_registered}
    end
  end

  @doc """
  Removes a users game room from availablity.
  """
  @spec unregister(RPS.Accounts.User.t()) :: :ok
  def unregister(user) do
    Registry.unregister(__MODULE__, user.id)
  end

  @doc """
  Lists all currently avilable game rooms.
  """
  @spec all :: [{binary(), pid(), binary()}]
  def all do
    spec = [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}]
    Registry.select(__MODULE__, spec)
  end

  @doc """
  Finds a game room by user id.
  """
  @spec find(user_id :: binary()) :: {:error, :not_found} | {:ok, pid}
  def find(user_id) do
    case Registry.lookup(__MODULE__, user_id) do
      [] -> {:error, :not_found}
      [{room, _}] -> {:ok, room}
    end
  end
end
