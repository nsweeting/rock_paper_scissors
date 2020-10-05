defmodule RPSWeb.SessionController do
  use RPSWeb.Definitions, :controller

  alias RPS.Accounts

  @spec new(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def new(conn, _params) do
    render(conn)
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"login" => params}) do
    case Accounts.authenticate_user(params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> redirect(to: "/")

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid username or password.")
        |> render("new.html")
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    conn
    |> put_session(:user_id, nil)
    |> redirect(to: "/login")
  end
end
