defmodule RPS.Accounts do
  alias RPS.Accounts.Users

  defdelegate new_user, to: Users, as: :new

  defdelegate create_user(params), to: Users, as: :create

  defdelegate authenticate_user(params), to: Users, as: :authenticate

  defdelegate authenticate_user(username, password), to: Users, as: :authenticate

  defdelegate fetch_user(id), to: Users, as: :fetch
end
