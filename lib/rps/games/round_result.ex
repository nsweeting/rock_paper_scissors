defmodule RPS.Games.RoundResult do
  @moduledoc """
  A struct used to contain the results of a single game round.
  """

  defstruct [
    :round_count,
    :p1_hand,
    :p1_username,
    :p2_hand,
    :p2_username,
    :winner
  ]

  @type t :: %__MODULE__{}

  ################################
  # Public API
  ################################

  @doc """
  Creates the result of a game round between two players
  """
  @spec new(integer(), RPS.Games.Player.t(), atom(), RPS.Games.Player.t(), atom()) ::
          RPS.Games.RoundResult.t()
  def new(round_count, p1, p1_hand, p2, p2_hand) do
    params = %{
      round_count: round_count,
      p1_hand: p1_hand,
      p1_username: p1.user.username,
      p2_hand: p2_hand,
      p2_username: p2.user.username,
      winner: get_winner(p1, p1_hand, p2, p2_hand)
    }

    struct(__MODULE__, params)
  end

  ################################
  # Private API
  ################################

  defp get_winner(_p1, :rock, _p2, :rock), do: :draw
  defp get_winner(_p1, :rock, p2, :paper), do: p2
  defp get_winner(p1, :rock, _p2, :scissors), do: p1
  defp get_winner(_p1, :paper, _p2, :paper), do: :draw
  defp get_winner(p1, :paper, _p2, :rock), do: p1
  defp get_winner(_p1, :paper, p2, :scissors), do: p2
  defp get_winner(_p1, :scissors, _p2, :scissors), do: :draw
  defp get_winner(_p1, :scissors, p2, :rock), do: p2
  defp get_winner(p1, :scissors, _p2, :paper), do: p1
end
