defmodule RPSWeb.LobbyLiveTest do
  use RPSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias RPS.Games

  test "will redirect if not authenticated", %{conn: conn} do
    {:error, {:redirect, _}} = live(conn, "/lobby")
  end

  test "will wait for rooms", %{conn: conn} do
    user = insert(:user)
    conn = authenticate(conn, user)

    assert {:ok, liveview, waiting_html} = live(conn, "/lobby")
    assert waiting_html =~ "Waiting for rooms..."
  end
end
