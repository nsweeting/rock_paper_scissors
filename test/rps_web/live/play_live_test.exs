defmodule RPSWeb.PlayLiveTest do
  use RPSWeb.ConnCase

  import Phoenix.LiveViewTest

  alias RPS.Games

  test "will redirect if not authenticated", %{conn: conn} do
    {:error, {:redirect, _}} = live(conn, "/play")
  end

  test "will wait for an opponent", %{conn: conn} do
    user = insert(:user)
    conn = authenticate(conn, user)

    assert {:ok, liveview, waiting_html} = live(conn, "/play")
    assert waiting_html =~ "Waiting for opponent..."
  end

  test "will start a room", %{conn: conn} do
    user = insert(:user)
    conn = authenticate(conn, user)

    assert [] = Games.all_rooms()
    assert {:ok, liveview, waiting_html} = live(conn, "/play")
    assert [{username, _, _}] = Games.all_rooms()
    assert username == user.id
  end
end
