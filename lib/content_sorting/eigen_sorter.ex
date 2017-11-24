defmodule SmileysData.ContentSorting.EigenSorter do
	@moduledoc """
	A content sorting algorithm inspired by the EigenTrust algorithm.  The decay portions simply add a window of time to the trusted content
	algorithm.  The reputation modifiers are an artificially slowed algorithm where over time after posting content, trust relationships
	develop between interactions with users and eventually spread to rooms.  A room and users reputation will eventually cause their content
	to not only rise faster, but also impact their search ranking.  Designed to be resilient against even high amounts of brigandiers. The
	primary goal is to simulate a pub where democracy does not exist but instead people are accountable to actions and can therefor learn and
	adjust.  Quoting The Orville: `A voice should be earned, not given away` and `I believe you are confusing opinion with knowledge`.
	"""
	@behaviour SmileysData.ContentSorting.ContentSorterBehaviour

	alias SmileysData.ContentSorting.SortSettings
	alias SmileysData.{Post, User, Room, QueryUser, QueryRoom}

	def decay_posts_new() do
	  %{time_window_new: {start_hour, end_hour}, depletion_ratio_new: ratio} = get_settings()

	  SmileysData.QueryPost.decay_posts(Float.to_string(ratio), "INTERVAL '" <> Integer.to_string(end_hour) <> " hours'", "INTERVAL '" <> Integer.to_string(start_hour) <> " hour'")
	end
  
	def decay_posts_medium() do
	  %{time_window_medium: {start_hour, end_hour}, depletion_ratio_medium: ratio} = get_settings()

	  SmileysData.QueryPost.decay_posts(Float.to_string(ratio), "INTERVAL '" <> Integer.to_string(end_hour) <> " hours'", "INTERVAL '" <> Integer.to_string(start_hour) <> " hour'")
	end

	def decay_posts_long() do
	  %{time_window_long: {start_hour, end_hour}, depletion_ratio_long: ratio} = get_settings()

	  SmileysData.QueryPost.decay_posts(Float.to_string(ratio), "INTERVAL '" <> Integer.to_string(end_hour) <> " hours'", "INTERVAL '" <> Integer.to_string(start_hour) <> " hour'")
	end

	def decay_posts_termination() do
	  %{time_window_terminator: {start_hour, end_hour}, depletion_ratio_terminator: ratio} = get_settings()

	  SmileysData.QueryPost.decay_posts(Float.to_string(ratio), "INTERVAL '" <> Integer.to_string(end_hour) <> " hours'", "INTERVAL '" <> Integer.to_string(start_hour) <> " hour'")
	end

	def user_adjust(%Post{} = post, %User{} = user, %Room{} = room, modifier) do
	  amountAdjust = cond do
	    SmileysData.QueryRoom.room_is_moderator(user.moderating, room.id) ->
	      # Moderator: at least 1 point available
	      1 + round(Enum.min([room.reputation, 30]) * 0.15)
	    true ->
	      round(Enum.min([user.reputation, 30]) * 0.15)
	  end

      if amountAdjust > 0 do
        _ = QueryUser.update_user_reputation(post, modifier * amountAdjust)
      end

	  :ok
	end

	def room_adjust(%Post{} = _post, %User{} = user, %Room{} = room, modifier) do
	  amountAdjust = cond do
        user.reputation >= 10 ->
          1 + round(Enum.min([user.reputation, 70]) * 0.05)
        true ->
          0
      end

      if amountAdjust > 0 do
      	_ = QueryRoom.update_room_reputation(room, modifier * amountAdjust)
      end

	  :ok
	end

	@doc """
	Return the default set of sort settings
	"""
	def get_settings() do
		%SortSettings{}
	end

end