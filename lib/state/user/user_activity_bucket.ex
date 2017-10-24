defmodule SmileysData.State.User.ActivityBucket do
  @moduledoc """
  A bucket representing all of a users most recent activity including posts (from user) and notifications (to user). Keeps
  the latest @max_activity_count posts generally though prunes the oldest @prune_amount when and if more than max activities 
  reached.
  """

  use Agent

  alias SmileysData.State.User.Notification
  alias SmileysData.State.User.Activity 

  @max_activity_count 30
  @prune_amount 10

  @doc """
  Start with a new empty activity bucket
  """
  def start_link(name) do
    Agent.start_link(fn -> %{} end, name: {:via, :syn, name})
  end

  @doc """
  Get the activity of one of a users posts
  """
  def get_activity(user_bucket, %Activity{hash: hash}) do
    IO.inspect "HI LOOKING FOR THIS HASH " <> hash
    Agent.get(user_bucket, &Map.get(&1, hash))
  end

  def get_activity(user_bucket, %Notification{pinged_by: user_name}) do
    Agent.get(user_bucket, &Map.get(&1, user_name))
  end

  @doc """
  Return all of a users activity
  """
  def get_activity(user_bucket) do
  	Agent.get(user_bucket, fn state -> state end)
  end

  @doc """
  Deletes a single posts activity entry
  """
  def delete_activity(user_bucket, %Activity{hash: hash}) do
  	Agent.get_and_update(user_bucket, &Map.pop(&1, hash))
  end

  def delete_activity(user_bucket, %Notification{pinged_by: user_name}) do
    Agent.get_and_update(user_bucket, &Map.pop(&1, user_name))
  end

  @doc """
  Return the user bucket to an empty state
  """
  def reset_activity_bucket(user_bucket) do
  	Agent.update(user_bucket, fn -> %{} end)
  end

  @doc """
  Put new activity on a post in a users bucket, filed under the posts hash string. Get and update are used in order to increment
  counts since this is used on a per event basis.  Checks size of activity map.
  Returns new state of activity map
  """
  def add_new_activity(user_bucket, %Activity{user_name: user_name, hash: post_hash, comments: new_comments, votes: new_votes} = activity) do
    user_activity = Agent.get_and_update(user_bucket, fn state -> 
    	new_state = Map.update(state, post_hash, Map.replace(activity, :time, Time.utc_now()), fn %Activity{comments: comments, votes: votes, url: url} ->
	   		%Activity{hash: post_hash, user_name: user_name, time: Time.utc_now(), url: url, comments: comments + new_comments, votes: votes + new_votes}
    	end)
    	{new_state, new_state}
    end)

    # Maintainance operation
    _ = map_size_check(user_bucket, user_activity)

    user_activity[post_hash]
  end

  @doc """
  Put new notification in a users bucket, filed under the user name who pinged, since a user can only ping the same person once.
  Returns new state
  """
  def add_new_activity(user_bucket, %Notification{pinged_by: user_name} = notification) do
    user_activity = Agent.get_and_update(user_bucket, fn state -> 
      new_state = Map.update(state, user_name, Map.replace(notification, :time, Time.utc_now()), fn notif_to_update ->
        Map.replace(notif_to_update, :time, Time.utc_now())
      end)
      {new_state, new_state}
    end)

    # Maintainance operation
    _ = map_size_check(user_bucket, user_activity)

    user_activity[user_name]
  end

  defp map_size_check(user_bucket, activity) do
  	cond do 
  		Enum.count(activity) > @max_activity_count ->
	  		activity_sorted = Enum.sort(activity, fn %{time: time1}, %{time: time2} -> 
	  			time1 >= time2
	  		end)

	  		# Gather last x sorted keys
	  		_ = filter_activity_map(user_bucket, activity_sorted)
	  	true ->
	  		:noop
  	end
  end

  defp filter_activity_map(user_bucket, activity) do
  	filter_activity_map(user_bucket, activity, @prune_amount, 0)
  end

  defp filter_activity_map(_, _, 0, amount_pruned) do
  	amount_pruned
  end

  defp filter_activity_map(_, [], _, amount_pruned) do
  	amount_pruned
  end

  defp filter_activity_map(user_bucket, [%Activity{hash: hash}|activity], prune, amount_pruned) do
  	_ = delete_activity(user_bucket, hash)

  	filter_activity_map(user_bucket, activity, prune - 1, amount_pruned + 1)
  end

  defp filter_activity_map(user_bucket, [%Notification{pinged_by: user_name}|activity], prune, amount_pruned) do
    _ = delete_activity(user_bucket, user_name)

    filter_activity_map(user_bucket, activity, prune - 1, amount_pruned + 1)
  end
end