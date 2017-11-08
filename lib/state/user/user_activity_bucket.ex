defmodule SmileysData.State.User.ActivityBucket do
  @moduledoc """
  A bucket representing all of a users most recent activity including posts (from user) and notifications (to user). Keeps
  the latest @max_activity_count posts generally though prunes the oldest @prune_amount when and if more than max activities 
  reached.
  """

  use GenServer

  alias SmileysData.State.User.Notification
  alias SmileysData.State.User.Activity 

  @max_activity_count 30
  @prune_amount 10
  @activity_hours_to_live 72

  # Init

  @doc """
  Start with a new empty activity bucket
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: {:via, :syn, name})
  end

  def init(:ok) do
    {:ok, %{}}
  end

  # Client

  @doc """
  Get the activity of one of a users posts
  """
  def get_activity(user_bucket, %Activity{hash: hash}) do
    GenServer.call(user_bucket, {:retrieve_one, hash})
  end

  def get_activity(user_bucket, %Notification{pinged_by: user_name}) do
    GenServer.call(user_bucket, {:retrieve_one, user_name})
  end

  @doc """
  Return all of a users activity
  """
  def get_activity(user_bucket) do
    GenServer.call(user_bucket, :retrieve)
  end

  @doc """
  Deletes a single posts activity entry
  """
  def delete_activity(user_bucket, %Activity{hash: hash}) do
    GenServer.cast(user_bucket, {:delete_one, hash})
  end

  def delete_activity(user_bucket, %Notification{pinged_by: user_name}) do
    GenServer.cast(user_bucket, {:delete_one, user_name})
  end

  @doc """
  Return the user bucket to an empty state
  """
  def reset_activity_bucket(user_bucket) do
    GenServer.cast(user_bucket, :delete)
  end

  @doc """
  Put new activity on a post in a users bucket, filed under the posts hash string. Get and update are used in order to increment
  counts since this is used on a per event basis.  Checks size of activity map.
  Returns new state of activity map
  """
  def add_new_activity(user_bucket, %Activity{hash: post_hash} = activity) do
    user_activity = GenServer.call(user_bucket, {:add_activity, activity})

    set_activity_elimination_timer(user_bucket, activity)

    # Maintainance operation
    _ = map_size_check(user_bucket, user_activity)

    user_activity[post_hash]
  end

  @doc """
  Put new notification in a users bucket, filed under the user name who pinged, since a user can only ping the same person once.
  Returns new state
  """
  def add_new_activity(user_bucket, %Notification{pinged_by: user_name} = notification) do
    user_activity = GenServer.call(user_bucket, {:add_notification, notification})

    set_activity_elimination_timer(user_bucket, notification)

    # Maintainance operation
    _ = map_size_check(user_bucket, user_activity)

    user_activity[user_name]
  end

  @doc """
  Set a timer that reverses activity counts when complete
  """
  def set_activity_elimination_timer(user_bucket, activity) do
    Process.send_after(user_bucket, {:expire_activity, activity}, @activity_hours_to_live * 60 * 60 * 1000)
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

  # Server

  def handle_cast({:delete_one, key}, activity) do
    {:noreply, Map.pop(activity, key)}
  end

  def handle_cast(:delete, _) do
    {:noreply, %{}}
  end

  def handle_call({:retrieve_one, key}, _from, activity) do
    {:reply, activity[key], activity}
  end

  def handle_call(:retrieve, _from, activity) do
    {:reply, activity, activity}
  end

  def handle_call({:add_activity, %Activity{hash: hash, comments: new_comments, votes: new_votes} = new_activity}, _from, activity) do
    new_state = Map.update(activity, hash, new_activity, fn %Activity{user_name: user_name, comments: comments, votes: votes, url: url} ->
      %Activity{hash: hash, user_name: user_name, time: Time.utc_now(), url: url, comments: comments + new_comments, votes: votes + new_votes}
    end)

    {:reply, new_state, new_state}
  end

  def handle_call({:add_notification, %Notification{pinged_by: user_name, url: url} = new_activity}, _from, activity) do
    new_state = Map.update(activity, user_name, new_activity, fn notif_to_update ->
      Map.replace(notif_to_update, :time, Time.utc_now())
        |> Map.replace(:url, url)
    end)

    {:reply, new_state, new_state}
  end

  def handle_info({:expire_activity, activity}, state) do
    key = case activity do
      %Activity{hash: post_hash} ->
        post_hash
      %Notification{pinged_by: user_name} ->
        user_name
    end

    {:noreply, Map.pop(state, key)}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end