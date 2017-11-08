defmodule SmileysData.State.Post.ActivityBucket do
  @moduledoc """
  A bucket representing all of a posts activity. Currently only contains a comment count and lives for @post_activity_hours_to_live
  """

  use GenServer

  alias SmileysData.State.Post.Activity

  @post_server_hours_to_live 72

  @doc """
  Start with a new empty activity bucket
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [name: {:via, :syn, name}])
  end

  def init(:ok) do
    Process.send_after(self(), :timeout, @post_server_hours_to_live * 60 * 60 * 1000)

    {:ok, %Activity{}}
  end

  # Client
  ##########################

  @doc """
  Get the activity map of a post
  """
  def get_activity(post_bucket) do
    GenServer.call(post_bucket, :retrieve)
  end

  @doc """
  Put new activity on a post in a users bucket, filed under the posts hash string. Get and update are used in order to increment
  counts since this is used on a per event basis.  Checks size of activity map.
  Returns new state of activity map
  """
  def increment_post_bucket_activity(room_bucket, activity) do
    GenServer.call(room_bucket, {:update, activity})
  end

  # Server
  ###########################

  def handle_call(:retrieve, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:update, %Activity{comments: new_comments}}, _from, %Activity{comments: comments, hash: hash}) do
    new_activity_state = %Activity{hash: hash, comments: new_comments + comments}
    {:reply, new_activity_state, new_activity_state}
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  def handle_info(_, state), do: {:noreply, state}
end