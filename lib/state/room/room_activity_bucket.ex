defmodule SmileysData.State.Room.ActivityBucket do
  @moduledoc """
  A bucket representing all of a rooms activity.
  """

  use GenServer, restart: :temporary

  alias SmileysData.State.Timer.ActivityExpire

  alias SmileysData.State.Room.Activity

  # 1 week
  @room_activity_hours_to_live 168


  @doc """
  Start with a new empty activity bucket
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: {:via, :syn, name})
  end

  def init(:ok) do  
    {:ok, %Activity{}}
  end

  # Client
  ##########################

  @doc """
  Get the activity map of a room
  """
  def get_activity(room_bucket) do
    GenServer.call(room_bucket, :retrieve)
  end

  @doc """
  Add new activity to a room
  """
  def increment_room_bucket_activity(room_bucket, %Activity{} = activity) do
    ActivityExpire.expire_activity(activity, @room_activity_hours_to_live * 60 * 60 * 1000)

    GenServer.call(room_bucket, {:update, activity})
  end

  def increment_room_bucket_activity(room_bucket, %Activity{} = activity, :no_expire) do
    GenServer.call(room_bucket, {:update, activity})
  end

  # Server
  ###########################
  def handle_call(:retrieve, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:update, %Activity{subs: new_subs, new_posts: new_new_posts, hot_posts: new_hot_posts}}, _from, %Activity{room: room, subs: subs, new_posts: new_posts, hot_posts: hot_posts}) do
    
    new_activity_state = %Activity{room: room, subs: new_subs + subs, new_posts: new_new_posts + new_posts, hot_posts: new_hot_posts + hot_posts}
    
    {:reply, new_activity_state, new_activity_state}
  end

  def handle_info({:expire_activity, %Activity{subs: new_subs, new_posts: new_new_posts, hot_posts: new_hot_posts}}, %Activity{room: room, subs: subs, new_posts: new_posts, hot_posts: hot_posts}) do

    new_activity_state = %Activity{room: room, subs: new_subs + subs, new_posts: new_new_posts + new_posts, hot_posts: new_hot_posts + hot_posts}
    
    {:noreply, new_activity_state}
  end

  def handle_info(_, state), do: {:noreply, state}
end