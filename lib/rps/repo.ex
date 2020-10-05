defmodule RPS.Repo do
  use Ecto.Repo, otp_app: :rps, adapter: Ecto.Adapters.Postgres

  ################################
  # Ecto.Repo Callbacks
  ################################

  @doc false
  @impl Ecto.Repo
  def init(_type, opts) do
    Application.ensure_all_started(:exenv)

    extra_opts = [
      url: System.fetch_env!("RPS_DATABASE_URL"),
      pool_size: String.to_integer(System.get_env("RPS_DATABASE_POOL") || "10")
    ]

    {:ok, Keyword.merge(opts, extra_opts)}
  end

  defoverridable get: 2, get: 3

  @impl Ecto.Repo
  def get(query, id, opts \\ []) do
    super(query, id, opts)
  rescue
    Ecto.Query.CastError -> nil
  end
end
