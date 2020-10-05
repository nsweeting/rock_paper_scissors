defmodule RPS.Supervisor do
  @moduledoc """
  The RPS supervisor process.

  See https://hexdocs.pm/elixir/Supervisor.html for more information on OTP
  Supervisors.
  """

  use Supervisor

  ################################
  # Public API
  ################################

  @doc false
  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  @doc """
  Starts the Core supervisor process.
  """
  @spec start_link :: Supervisor.on_start()
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Reload any configuration on application upgrades.
  """
  @spec config_change(changed :: term(), removed :: term()) :: term()
  def config_change(_changed, _removed) do
    :ok
  end

  ################################
  # Supervisor Callbacks
  ################################

  @doc false
  @impl Supervisor
  def init(_init_arg) do
    children = [
      RPS.Repo,
      RPS.Stats,
      RPS.Games.RoomRegistry,
      RPS.Games.RoomSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
