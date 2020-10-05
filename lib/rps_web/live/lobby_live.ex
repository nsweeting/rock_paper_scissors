defmodule RPSWeb.LobbyLive do
  use RPSWeb.Definitions, :live_view

  alias RPS.{Games, Stats}

  @poll_interval 500
  @init_assigns [
    rooms: [],
    stats: []
  ]

  ################################
  # Phoenix.LiveView Callbacks
  ################################

  @impl true
  def mount(_params, session, socket) do
    socket = do_startup(session, socket)
    {:ok, socket}
  end

  @impl true
  def handle_info(:poll_rooms, socket) do
    socket = poll_rooms(socket)
    {:noreply, socket}
  end

  def handle_info(:poll_stats, socket) do
    socket = poll_stats(socket)
    {:noreply, socket}
  end

  ################################
  # Private API
  ################################

  defp poll_rooms(socket) do
    rooms = Games.all_rooms()
    Process.send_after(self(), :poll_rooms, @poll_interval)
    assign(socket, :rooms, rooms)
  end

  defp poll_stats(socket) do
    stats = Stats.all()
    Process.send_after(self(), :poll_stats, @poll_interval)
    assign(socket, :stats, stats)
  end

  defp do_startup(session, socket) do
    socket = assign(socket, @init_assigns)

    if connected?(socket) do
      send(self(), :poll_rooms)
      send(self(), :poll_stats)
      authenticate(session, socket)
    else
      socket
    end
  end
end
