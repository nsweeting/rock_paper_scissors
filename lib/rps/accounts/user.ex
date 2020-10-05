defmodule RPS.Accounts.User do
  @moduledoc """
  Schema for users.
  """

  use RPS.Definitions, :schema

  @username_regex ~r/^[A-Za-z0-9]+(?:[ _-][A-Za-z0-9]+)*$/

  schema "users" do
    field(:username, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, RPS.Accounts.UserPassword)

    timestamps(type: :utc_datetime)
  end

  ################################
  # Public API
  ################################

  @doc """
  Creates an `Ecto.Changeset` for the given action.
  """
  @spec changeset(RPS.Accounts.User.t(), atom(), map()) :: Ecto.Changeset.t()
  def changeset(struct, :new, params) do
    cast(struct, params, [])
  end

  def changeset(struct, :create, params) do
    struct
    |> cast(params, [:username, :password, :password_confirmation])
    |> validate_username()
    |> validate_password()
  end

  ################################
  # Private API
  ################################

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_format(:username, @username_regex)
    |> validate_length(:username, min: 5, max: 30)
    |> unique_constraint(:username, name: :users_username_index)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 8, max: 100)
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_format(:password, ~r/[0-9]+/, message: "must contain a number")
    |> validate_format(:password, ~r/[A-Z]+/, message: "must contain an upper-case letter")
    |> validate_format(:password, ~r/[a-z]+/, message: "must contain a lower-case letter")
    |> validate_format(:password, ~r/[#\!\?&@\$%^&*\(\)]+/, message: "must contain a symbol")
    |> put_field_hash(:password)
  end

  defp put_field_hash(changeset, field) do
    if changeset.valid? do
      case fetch_change(changeset, field) do
        {:ok, change} ->
          field = String.to_existing_atom("#{field}_hash")
          put_change(changeset, field, change)

        :error ->
          changeset
      end
    else
      changeset
    end
  end
end
