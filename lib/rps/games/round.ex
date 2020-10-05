defmodule RPS.Games.Round do
  @moduledoc """
  A process used to host a single game round between players.
  """

  use GenServer

  alias RPS.Games.RoundResult
  alias RPS.Stats

  @type round :: GenServer.server()

  @hands [:rock, :paper, :scissors]

  ################################
  # Public API
  ################################

  @doc """
  Starts the game round process.
  """
  @spec start_link(integer(), RPS.Games.Player.t(), RPS.Games.Player.t()) :: GenServer.on_start()
  def start_link(round_count, p1, p2) do
    GenServer.start_link(__MODULE__, {self(), round_count, p1, p2})
  end

  @doc """
  Plays a hand in the round.
  """
  @spec play(tuple(), atom()) :: :ok
  def play({round, ref}, hand) when hand in @hands do
    GenServer.cast(round, {:play_hand, ref, hand})
  end

  @doc """
  Cancels a round.
  """
  @spec cancel(round()) :: :ok
  def cancel(round) do
    GenServer.stop(round)
  end

  ################################
  # GenServer Callbacks
  ################################

  def init({room, round_count, p1, p2}) do
    state = init_state(room, round_count, p1, p2)
    {:ok, state, {:continue, :start_round}}
  end

  def handle_continue(:start_round, state) do
    state = start_round(state)
    {:noreply, state}
  end

  def handle_continue(:maybe_play_round, state) do
    maybe_play_round(state)
    {:noreply, state}
  end

  def handle_cast({:play_hand, ref, hand}, state) do
    state = play_hand(state, ref, hand)
    {:noreply, state, {:continue, :maybe_play_round}}
  end

  def handle_info(:play_round, state) do
    state = play_round(state)
    {:stop, :normal, state}
  end

  def handle_info(:round_timeout, state) do
    state = round_timeout(state)
    {:stop, :normal, state}
  end

  ################################
  # Private API
  ################################

  defp init_state(room, round_count, p1, p2) do
    %{
      room: room,
      round_count: round_count,
      p1: p1,
      p2: p2,
      p1_hand_ref: nil,
      p2_hand_ref: nil,
      p1_hand: nil,
      p2_hand: nil,
      timeout: Application.get_env(:rps, :round_timeout, 10_000),
      timeout_ref: nil,
      result: nil
    }
  end

  defp start_round(state) do
    state = %{state | p1_hand_ref: make_ref(), p2_hand_ref: make_ref()}
    send(state.p1.pid, {:start_round, {self(), state.p1_hand_ref}, state.timeout})
    send(state.p2.pid, {:start_round, {self(), state.p2_hand_ref}, state.timeout})
    timeout_ref = Process.send_after(self(), :round_timeout, state.timeout)
    %{state | timeout_ref: timeout_ref}
  end

  defp play_hand(%{p1_hand_ref: p1_ref} = state, ref, hand) when p1_ref == ref do
    %{state | p1_hand: hand}
  end

  defp play_hand(%{p2_hand_ref: p2_ref} = state, ref, hand) when p2_ref == ref do
    %{state | p2_hand: hand}
  end

  defp maybe_play_round(state) do
    if state.p1_hand != nil and state.p2_hand != nil do
      send(self(), :play_round)
    end
  end

  defp play_round(state) do
    result = RoundResult.new(state.round_count, state.p1, state.p1_hand, state.p2, state.p2_hand)
    send(state.room, {:round_result, result})
    Stats.add_result(result)
    %{state | result: result}
  end

  defp round_timeout(state) do
    p1_hand = state.p1_hand || Enum.random(@hands)
    p2_hand = state.p2_hand || Enum.random(@hands)
    state = %{state | p1_hand: p1_hand, p2_hand: p2_hand}
    play_round(state)
  end
end
