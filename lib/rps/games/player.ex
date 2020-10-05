defmodule RPS.Games.Player do
  @moduledoc """
  A struct used to contain information on game players.
  """

  defstruct [
    :user,
    :pid,
    :ref
  ]

  @type t :: %__MODULE__{}

  ################################
  # Public API
  ################################

  @doc """
  Creates a new game player.
  """
  @spec new(RPS.Accounts.User.t(), pid(), reference()) :: RPS.Games.Player.t()
  def new(user, pid, ref) do
    struct(__MODULE__, user: user, pid: pid, ref: ref)
  end
end
