defmodule RPS.Stats do
  @moduledoc """
  A process used to maintain stats on players.
  """

  use GenServer

  @table __MODULE__

  ################################
  # Public API
  ################################

  @doc """
  Starts the stats process.
  """
  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Adds a round result to the stats.
  """
  @spec add_result(RPS.Games.RoundResult.t()) :: :ok
  def add_result(result) do
    GenServer.cast(__MODULE__, {:add_result, result})
  end

  @doc """
  Gets the stats for a user by username.
  """
  @spec get(binary()) :: {:ok, tuple()} | {:error, :not_found}
  def get(username) do
    case :ets.lookup(__MODULE__, username) do
      [stats] -> {:ok, stats}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Gets all the current stats.
  """
  @spec all :: [tuple()]
  def all do
    stats = :ets.tab2list(__MODULE__)
    Enum.sort_by(stats, &elem(&1, 3), &>=/2)
  end

  ################################
  # GenServer Callbacks
  ################################

  @impl GenServer
  def init(:ok) do
    init_table()
    {:ok, :ok}
  end

  @impl GenServer
  def handle_cast({:add_result, result}, state) do
    do_add_result(result)
    {:noreply, state}
  end

  ################################
  # Private API
  ################################

  defp init_table do
    :ets.new(@table, [:named_table, :protected])
  end

  defp do_add_result(result) do
    maybe_init_users(result)
    add_rounds_played(result)
    add_rounds_won(result)
  end

  defp maybe_init_users(result) do
    :ets.insert_new(__MODULE__, {result.p1_username, 0, 0, 0.0})
    :ets.insert_new(__MODULE__, {result.p2_username, 0, 0, 0.0})
  end

  defp add_rounds_played(result) do
    do_add_played_games(result.p1_username)
    do_add_played_games(result.p2_username)
  end

  defp do_add_played_games(username) do
    {:ok, {username, rounds_won, rounds_played, _}} = get(username)
    do_insert(username, rounds_won, rounds_played + 1)
  end

  defp add_rounds_won(result) do
    if is_map(result.winner) do
      {:ok, {username, rounds_won, rounds_played, _}} = get(result.winner.user.username)
      do_insert(username, rounds_won + 1, rounds_played)
    end
  end

  defp do_insert(username, rounds_won, rounds_played) do
    record = {username, rounds_won, rounds_played, rounds_won / rounds_played}
    :ets.insert(__MODULE__, record)
  end
end
