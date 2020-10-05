defmodule RPSWeb.LiveHelpers do
  import Phoenix.LiveView, only: [redirect: 2, assign: 3]

  alias RPS.Accounts

  @spec authenticate(map(), Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def authenticate(session, socket) do
    with {:ok, user_id} <- fetch_user_id(session, socket) do
      fetch_user(socket, user_id)
    end
  end

  @spec authenticated?(Phoenix.LiveView.Socket.t()) :: boolean()
  def authenticated?(socket) do
    socket.assigns[:current_user] != nil
  end

  defp fetch_user_id(%{"user_id" => user_id}, _socket) when is_binary(user_id) do
    {:ok, user_id}
  end

  defp fetch_user_id(_, socket) do
    unauthorized(socket)
  end

  defp fetch_user(socket, user_id) do
    case Accounts.fetch_user(user_id) do
      {:ok, user} -> assign(socket, :current_user, user)
      {:error, _} -> unauthorized(socket)
    end
  end

  defp unauthorized(socket) do
    redirect(socket, to: "/login")
  end
end
