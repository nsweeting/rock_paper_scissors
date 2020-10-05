defmodule RPS.Definitions do
  @moduledoc """
  The entrypoint for defining your application interface, such
  as schemas, services and so on.

  This can be used in your application as:

      use RPS.Definitions, :schema
      use RPS.Definitions, :service

  The definitions below will be executed for every schema,
  service, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def schema do
    quote do
      use Ecto.Schema

      import Ecto.Changeset

      @type t :: %__MODULE__{}

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  def service do
    quote do
      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]

      alias RPS.Repo
      alias Ecto.{Changeset, Multi}
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
