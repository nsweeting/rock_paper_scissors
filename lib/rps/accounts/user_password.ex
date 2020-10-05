defmodule RPS.Accounts.UserPassword do
  @moduledoc false

  @behaviour Ecto.Type

  ################################
  # Public API
  ################################

  @doc false
  def hash(password) do
    Argon2.hash_pwd_salt(password)
  end

  @doc false
  @spec verify(binary(), binary()) :: boolean()
  def verify(password, password_hash) do
    Argon2.verify_pass(password, password_hash)
  end

  @doc false
  @spec fake_verify() :: false
  def fake_verify do
    Argon2.no_user_verify()
  end

  ################################
  # Ecto.Type Callbacks
  ################################

  @doc false
  @impl true
  def type, do: :binary

  @doc false
  @impl true
  def cast(value), do: {:ok, value}

  @doc false
  @impl true
  def dump(value), do: {:ok, hash(value)}

  @doc false
  @impl true
  def load(value), do: {:ok, value}

  @doc false
  @impl true
  def embed_as(_format), do: :self

  @doc false
  @impl true
  def equal?(val1, val2), do: val1 == val2
end
