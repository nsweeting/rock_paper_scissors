defmodule RPSWeb.PlayLive do
  use RPSWeb.Definitions, :live_view

  alias RPS.Games

  @init_assigns [
    host: false,
    room: nil,
    status: :waiting,
    round: nil,
    countdown: nil,
    countdown_ref: nil,
    room_info: nil,
    current_hand: nil,
    buttons: nil,
    final_results: nil,
    final_winner: nil
  ]

  ################################
  # Phoenix.LiveView Callbacks
  ################################

  @impl true
  def mount(params, session, socket) do
    socket = do_startup(params, session, socket)
    {:ok, socket}
  end

  @impl true
  def handle_event("play_rock", _, socket) do
    socket = play_round(socket, :rock)
    {:noreply, socket}
  end

  def handle_event("play_paper", _, socket) do
    socket = play_round(socket, :paper)
    {:noreply, socket}
  end

  def handle_event("play_scissors", _, socket) do
    socket = play_round(socket, :scissors)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:init, params}, socket) do
    socket = do_init(socket, params)
    {:noreply, socket}
  end

  def handle_info({:start_round, round, timeout}, socket) do
    socket = start_round(socket, round, timeout)
    {:noreply, socket}
  end

  def handle_info(:player_exit, socket) do
    socket = player_exit(socket)
    {:noreply, socket}
  end

  def handle_info({:round_result, _result}, socket) do
    {:noreply, socket}
  end

  def handle_info({:room_complete, info, final_result, final_winner}, socket) do
    socket = room_complete(socket, info, final_result, final_winner)
    {:noreply, socket}
  end

  def handle_info({:countdown, countdown, ref}, socket) do
    socket = do_countdown(socket, countdown, ref)
    {:noreply, socket}
  end

  ################################
  # Private API
  ################################

  defp do_startup(params, session, socket) do
    socket = assign(socket, @init_assigns)

    if connected?(socket) do
      session
      |> authenticate(socket)
      |> maybe_init(params)
    else
      socket
    end
  end

  defp maybe_init(socket, params) do
    if authenticated?(socket) do
      send(self(), {:init, params})
      socket
    else
      socket
    end
  end

  defp do_init(socket, %{"room" => user_id}), do: join_room(socket, user_id)
  defp do_init(socket, _params), do: start_room(socket)

  defp join_room(socket, user_id) do
    with {:ok, socket} <- find_room(socket, user_id) do
      do_join_room(socket)
    end
  end

  defp find_room(socket, user_id) do
    case Games.find_room(user_id) do
      {:ok, room} ->
        {:ok, assign(socket, :room, room)}

      {:error, _} ->
        socket
        |> put_flash(:error, "Failed to find match.")
        |> redirect(to: "/")
    end
  end

  defp do_join_room(socket) do
    case Games.join_room(socket.assigns.room, socket.assigns.current_user) do
      :ok ->
        assign(socket, host: false, status: :waiting)

      _ ->
        socket
        |> put_flash(:error, "You cannot join a room hosted by yourself.")
        |> redirect(to: "/")
    end
  end

  defp start_room(socket) do
    case Games.start_room(socket.assigns.current_user) do
      {:ok, room} ->
        assign(socket,
          host: true,
          status: :waiting,
          room: room,
          current_hand: nil,
          round: nil,
          room_info: nil,
          buttons: nil,
          countdown: nil
        )

      {:error, _} ->
        socket
        |> put_flash(:error, "You already are hosting a room.")
        |> redirect(to: "/")
    end
  end

  defp start_round(socket, round, timeout) do
    countdown = round(timeout / 1000)
    info = Games.room_info(socket.assigns.room)
    socket = do_countdown(socket, countdown, socket.assigns.countdown_ref)

    assign(socket,
      status: :playing,
      current_hand: nil,
      round: round,
      room_info: info,
      buttons: nil
    )
  end

  defp player_exit(socket) do
    socket = put_flash(socket, :error, "Opponent exited match.")

    if not socket.assigns.host do
      redirect(socket, to: "/")
    else
      start_room(socket)
    end
  end

  defp play_round(socket, hand) do
    if socket.assigns.current_hand == nil do
      Games.play_round(socket.assigns.round, hand)
      assign(socket, current_hand: hand, buttons: "disabled")
    else
      socket
    end
  end

  defp do_countdown(socket, 0, _), do: socket

  defp do_countdown(socket, countdown, ref) do
    if socket.assigns.countdown_ref == ref do
      ref = make_ref()
      Process.send_after(self(), {:countdown, countdown - 1, ref}, 1000)
      assign(socket, countdown: countdown, countdown_ref: ref)
    else
      socket
    end
  end

  defp room_complete(socket, info, final_results, final_winner) do
    assign(socket,
      status: :complete,
      room_info: info,
      final_results: final_results,
      final_winner: final_winner,
      room: nil,
      current_hand: nil,
      buttons: "disabled",
      round: nil,
      countdown: nil,
      countdown_ref: nil
    )
  end
end
