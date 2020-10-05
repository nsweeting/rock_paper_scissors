defmodule RPS.Accounts.Users do
  @moduledoc """
  Service layers for account users.
  """

  use RPS.Definitions, :service

  alias RPS.Accounts.{User, UserPassword}

  ################################
  # Public API
  ################################

  @spec new() :: Ecto.Changeset.t()
  def new do
    User.changeset(%User{}, :new, %{})
  end

  @spec create(map()) :: {:ok, RPS.Accounts.User.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    %User{}
    |> User.changeset(:create, params)
    |> Repo.insert()
  end

  @spec authenticate(map()) :: {:error, :invalid} | {:ok, RPS.Accounts.User.t()}
  def authenticate(params) do
    with {:ok, username} <- Map.fetch(params, "username"),
         {:ok, password} <- Map.fetch(params, "password") do
      authenticate(username, password)
    else
      _ -> authenticate_failed()
    end
  end

  @spec authenticate(RPS.Accounts.User.t(), binary()) ::
          {:error, :invalid} | {:ok, RPS.Accounts.User.t()}
  def authenticate(%User{} = user, password) do
    case UserPassword.verify(password, user.password_hash) do
      true -> {:ok, user}
      _ -> authenticate_failed()
    end
  end

  def authenticate(username, password) when is_binary(username) do
    case Repo.get_by(User, username: username) do
      nil -> authenticate_failed()
      user -> authenticate(user, password)
    end
  end

  defp authenticate_failed do
    UserPassword.fake_verify()
    {:error, :invalid}
  end

  @spec fetch(any) :: {:error, :not_found} | {:ok, RPS.Accounts.User.t()}
  def fetch(id) do
    case Repo.get_by(User, id: id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end
end
