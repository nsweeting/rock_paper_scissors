defmodule RPSWeb.ControllerHelpers do
  import Plug.Conn, only: [get_session: 2, assign: 3, halt: 1]
  import Phoenix.Controller, only: [redirect: 2]

  alias RPS.Accounts

  @spec authenticate(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def authenticate(conn, _opts) do
    with {:ok, user_id} <- fetch_user_id(conn) do
      fetch_user(conn, user_id)
    end
  end

  defp fetch_user_id(conn) do
    user_id = get_session(conn, :user_id)

    if user_id do
      {:ok, user_id}
    else
      unauthorized(conn)
    end
  end

  defp fetch_user(conn, user_id) do
    case Accounts.fetch_user(user_id) do
      {:ok, user} -> assign(conn, :current_user, user)
      {:error, _} -> unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> redirect(to: "/login")
    |> halt()
  end
end
