defmodule RPS.Games do
  alias RPS.Games.{RoomRegistry, RoomSupervisor, Room, Round}

  defdelegate all_rooms, to: RoomRegistry, as: :all

  defdelegate find_room(user_id), to: RoomRegistry, as: :find

  defdelegate start_room(user), to: RoomSupervisor, as: :start

  defdelegate join_room(room, user), to: Room, as: :join

  defdelegate room_info(room), to: Room, as: :info

  defdelegate close_room(room), to: Room, as: :close

  defdelegate play_round(round, hand), to: Round, as: :play
end
