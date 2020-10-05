defmodule RPS.Games.Room do
  @moduledoc """
  A process used to host game rooms for players.
  """

  use GenServer, restart: :temporary

  alias RPS.Games.{Player, RoomRegistry, Round}

  @type room :: GenServer.server()
  @type user :: RPS.Accounts.User.t() | {RPS.Accounts.User.t(), pid()}

  @max_rounds 10
  @init_state %{
    p1: nil,
    p2: nil,
    active: false,
    round: nil,
    round_count: 0,
    results: [],
    final_results: nil,
    final_winner: nil,
    max_rounds: @max_rounds
  }

  ################################
  # Public API
  ################################

  @doc """
  Starts a game room process hosted by a user.
  """
  @spec start_link(user()) :: GenServer.on_start()
  def start_link({_user, _pid} = user) do
    GenServer.start_link(__MODULE__, user)
  end

  def start_link(user) do
    GenServer.start_link(__MODULE__, {user, self()})
  end

  @doc """
  Lets a user join an open game room.
  """
  @spec join(room(), RPS.Accounts.User.t()) :: any
  def join(room, user) do
    GenServer.call(room, {:join, user})
  end

  @doc """
  Gets info such as round results for a room.
  """
  @spec info(room()) :: map()
  def info(room) do
    GenServer.call(room, :info)
  end

  @doc """
  Closes a room.
  """
  @spec close(room()) :: :ok
  def close(room) do
    GenServer.stop(room)
  end

  ################################
  # GenServer Callbacks
  ################################

  @impl GenServer
  def init({user, pid}) do
    case init_state(user, pid) do
      {:ok, state} -> {:ok, state}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:join, user}, {pid, _ref}, state) do
    {result, state} = do_join(state, user, pid)
    {:reply, result, state, {:continue, :maybe_start_round}}
  end

  def handle_call(:info, _from, state) do
    info = do_info(state)
    {:reply, info, state}
  end

  @impl GenServer
  def handle_continue(:maybe_start_round, state) do
    state = maybe_start_round(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:round_result, result}, state) do
    state = round_result(state, result)
    {:noreply, state, {:continue, :maybe_start_round}}
  end

  def handle_info(:shutdown, state) do
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    state = stop_room(state, ref)
    {:stop, :normal, state}
  end

  ################################
  # Private API
  ################################

  defp init_state(user, pid) do
    with :ok <- RoomRegistry.register(user) do
      {:ok, new_player(@init_state, :p1, user, pid)}
    end
  end

  defp new_player(state, key, user, pid) do
    ref = Process.monitor(pid)
    player = Player.new(user, pid, ref)
    Map.put(state, key, player)
  end

  defp do_join(state, user, pid) do
    with {:ok, state} <- validate_open(state),
         {:ok, state} <- validate_user(state, user) do
      state = new_player(state, :p2, user, pid)
      RoomRegistry.unregister(state.p1.user)
      state = %{state | active: true}
      {:ok, state}
    end
  end

  defp validate_open(state) do
    if state.p2 == nil do
      {:ok, state}
    else
      {{:error, :room_full}, state}
    end
  end

  defp validate_user(state, user) do
    if state.p1.user == user do
      {{:error, :invalid_user}, state}
    else
      {:ok, state}
    end
  end

  defp maybe_start_round(%{active: true} = state) do
    if state.round_count + 1 > state.max_rounds do
      complete(state)
    else
      start_round(state)
    end
  end

  defp maybe_start_round(state), do: state

  defp start_round(state) do
    round_count = state.round_count + 1
    {:ok, round} = Round.start_link(round_count, state.p1, state.p2)
    %{state | round_count: round_count, round: round}
  end

  defp stop_room(state, ref) do
    state
    |> player_exit(ref, :p1, :p2)
    |> player_exit(ref, :p2, :p1)
  end

  defp player_exit(state, ref, key1, key2) do
    p1 = Map.get(state, key1)
    p2 = Map.get(state, key2)

    if is_map(p1) and p1.ref == ref do
      if is_map(p2) do
        send(p2.pid, :player_exit)
      end

      Map.put(state, key1, nil)
    else
      state
    end
  end

  defp round_result(state, result) do
    send_result(state, result)
    results = state.results ++ [result]
    %{state | round: nil, results: results}
  end

  defp send_result(state, result) do
    for pid <- [state.p1.pid, state.p2.pid] do
      send(pid, {:round_result, result})
    end
  end

  defp do_info(state) do
    %{
      round_count: state.round_count,
      p1: state.p1,
      p2: state.p2,
      results: state.results
    }
  end

  defp complete(state) do
    send(self(), :shutdown)
    info = do_info(state)
    state = %{state | active: false, round: nil}
    state = final_results(state)

    for pid <- [state.p1.pid, state.p2.pid] do
      send(pid, {:room_complete, info, state.final_results, state.final_winner})
    end

    state
  end

  defp final_results(state) do
    final_results = get_final_results(state, [state.p1, state.p2])
    final_winner = get_final_winner(final_results)
    %{state | final_results: final_results, final_winner: final_winner}
  end

  defp get_final_results(state, players) do
    players
    |> Enum.map(fn player -> {player, get_user_wins(state, player)} end)
    |> Enum.sort_by(&elem(&1, 1), &>=/2)
  end

  defp get_user_wins(state, player) do
    Enum.count(state.results, fn result -> result.winner == player end)
  end

  defp get_final_winner(final_results) do
    case final_results do
      [{_, wins1}, {_, wins2}] when wins1 == wins2 -> nil
      [{player, _}, _] -> player
    end
  end
end
