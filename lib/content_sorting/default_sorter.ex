defmodule SmileysData.ContentSorting.DefaultSorter do
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
	  %{terminator: {start_hour, end_hour}, depletion_ratio_terminator: ratio} = get_settings()

	  SmileysData.QueryPost.decay_posts(Float.to_string(ratio), "INTERVAL '" <> Integer.to_string(end_hour) <> " hours'", "INTERVAL '" <> Integer.to_string(start_hour) <> " hour'")
	end

	def user_adjust(%Post{} = post, %User{} = user, %Room{} = room, modifier) do
		# TODO: refactor. not bad but can more efficiently allocate rep
		QueryUser.update_user_reputation(post, user, room, modifier)

		:ok
	end

	def room_adjust(%Post{} = _post, %User{} = user, %Room{} = room, modifier) do
		# TODO: refactor. not bad but can more efficiently allocate rep
		QueryRoom.update_room_reputation(user, room, modifier)

		:ok
	end

	@doc """
	Return the default set of sort settings
	"""
	def get_settings() do
		%SortSettings{}
	end
end