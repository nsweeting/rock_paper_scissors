defmodule RPS.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: RPS.Repo

  def user_factory do
    %RPS.Accounts.User{
      username: sequence(:username, &"username-#{&1}"),
      password_hash: "password123"
    }
  end
end
