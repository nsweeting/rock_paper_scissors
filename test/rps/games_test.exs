defmodule RPS.GamesTest do
  use RPS.DataCase

  alias RPS.Games

  describe "all_rooms/0" do
    test "will list available game rooms" do
      user = insert(:user)

      assert {:ok, room} = Games.start_room(user)
      assert [{user_id, pid, username}] = Games.all_rooms()
      assert user.id == user_id
      assert room == pid
      assert user.username == username
    end

    test "will not list unavailable game rooms" do
      user = insert(:user)

      assert {:ok, room} = Games.start_room(user)
      assert [{_, _, _}] = Games.all_rooms()

      GenServer.stop(room)
      :timer.sleep(50)

      assert [] = Games.all_rooms()
    end
  end

  describe "find_room/1" do
    test "will find a room by a user id" do
      user = insert(:user)

      assert {:ok, room} = Games.start_room(user)
      assert {:ok, ^room} = Games.find_room(user.id)
    end

    test "will return error tuple if room is not found" do
      assert {:error, :not_found} = Games.find_room("foo")
    end
  end

  describe "start_room/1" do
    test "will start a room for a user" do
      user = insert(:user)

      assert {:ok, room} = Games.start_room(user)
      assert is_pid(room)
    end

    test "will return an error if host already started room" do
      user = insert(:user)

      assert {:ok, room} = Games.start_room(user)
      assert {:error, :already_registered} = Games.start_room(user)
    end
  end

  describe "join_room/2" do
    test "will let valid users join the room" do
      user1 = insert(:user)
      user2 = insert(:user)

      assert {:ok, room} = Games.start_room(user1)
      assert :ok = Games.join_room(room, user2)

      info = Games.room_info(room)

      assert info.p1.user == user1
      assert info.p2.user == user2
    end

    test "will not let the host join their own room" do
      user = insert(:user)

      assert {:ok, room} = Games.start_room(user)
      assert {:error, :invalid_user} = Games.join_room(room, user)
    end

    test "will not let users join a full room" do
      user1 = insert(:user)
      user2 = insert(:user)
      user3 = insert(:user)

      assert {:ok, room} = Games.start_room(user1)
      assert :ok = Games.join_room(room, user2)
      assert {:error, :room_full} = Games.join_room(room, user3)
    end

    test "will inform users that a round can start" do
      user1 = insert(:user)
      user2 = insert(:user)

      assert {:ok, room} = Games.start_room(user1)
      assert :ok = Games.join_room(room, user2)
      assert_receive {:start_round, _, 500}
      assert_receive {:start_round, _, 500}
    end

    test "will inform host if the joining player exits" do
      user1 = insert(:user)
      user2 = insert(:user)

      assert {:ok, room} = Games.start_room(user1)
      spawn(fn -> Games.join_room(room, user2) end)
      assert_receive :player_exit
    end
  end

  describe "room_info/1" do
    test "will return information about a room" do
      user = insert(:user)

      assert {:ok, room} = Games.start_room(user)

      info = Games.room_info(room)

      assert is_map(info.p1)
      assert info.p1.user == user
      assert info.p2 == nil
      assert info.round_count == 0
      assert info.results == []
    end
  end

  describe "play_round/2" do
    test "will let a user play the round" do
      user1 = insert(:user)
      user2 = insert(:user)

      assert {:ok, room} = Games.start_room(user1)
      assert :ok = Games.join_room(room, user2)
      assert_receive {:start_round, round1, _}
      assert_receive {:start_round, round2, _}
      assert :ok == Games.play_round(round1, :rock)
      assert :ok == Games.play_round(round2, :rock)
    end

    test "will send the user the round result" do
      user1 = insert(:user)
      user2 = insert(:user)

      assert {:ok, room} = Games.start_room(user1)
      assert :ok = Games.join_room(room, user2)
      assert_receive {:start_round, round1, _}
      assert_receive {:start_round, round2, _}

      Games.play_round(round1, :rock)
      Games.play_round(round2, :rock)

      assert_receive {:round_result, result1}
      assert_receive {:round_result, result2}

      assert result1 == result2
      assert result1.winner == :draw
    end

    test "will trigger the next round start" do
      user1 = insert(:user)
      user2 = insert(:user)

      assert {:ok, room} = Games.start_room(user1)
      assert :ok = Games.join_room(room, user2)
      assert_receive {:start_round, round1, _}
      assert_receive {:start_round, round2, _}

      Games.play_round(round1, :rock)
      Games.play_round(round2, :rock)

      assert_receive {:start_round, _, _}
      assert_receive {:start_round, _, _}
    end

    test "will not trigger new rounds past the max rounds" do
      user1 = insert(:user)
      user2 = insert(:user)

      assert {:ok, room} = Games.start_room(user1)
      assert :ok = Games.join_room(room, user2)

      for _ <- 1..10 do
        assert_receive {:start_round, round1, _}
        assert_receive {:start_round, round2, _}
        Games.play_round(round1, :rock)
        Games.play_round(round2, :rock)
        assert_receive {:round_result, _}
        assert_receive {:round_result, _}
      end

      refute_receive {:start_round, _, _}
      refute_receive {:start_round, _, _}
    end

    test "will return the final results after the max rounds" do
      user1 = insert(:user)
      user2 = insert(:user)

      assert {:ok, room} = Games.start_room(user1)
      assert :ok = Games.join_room(room, user2)

      for _ <- 1..10 do
        assert_receive {:start_round, round1, _}
        assert_receive {:start_round, round2, _}
        Games.play_round(round1, :rock)
        Games.play_round(round2, :scissors)
        assert_receive {:round_result, _}
        assert_receive {:round_result, _}
      end

      assert_receive {:room_complete, info, final_results, winner1}
      assert_receive {:room_complete, _, _, winner2}

      assert winner1 == winner2
      assert winner1.user == user1
      assert [{player1, 10}, {player2, 0}] = final_results
      assert player1.user == user1
      assert player2.user == user2
      assert Enum.count(info.results) == 10
    end

    test "will trigger an automatic play after timeout" do
      user1 = insert(:user)
      user2 = insert(:user)

      assert {:ok, room} = Games.start_room(user1)
      assert :ok = Games.join_room(room, user2)
      assert_receive {:start_round, _, 500}
      assert_receive {:start_round, _, 500}
      assert_receive {:round_result, _}, 600
      assert_receive {:round_result, _}, 600
    end
  end
end
