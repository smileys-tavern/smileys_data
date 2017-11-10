defmodule SmileysData.State.Timer.ActivityExpire do
  @moduledoc """
  A timer module that provides a client for setting activity event expirey
  """

  use GenServer

  alias SmileysData.State.Activity


  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: :activity_expire)
  end

  @doc """
  State will keep a count of active timers
  """
  def init(:ok) do
    {:ok, 0}
  end

  # Client
  ##########################

  @doc """
  Expire whatever is sent (activity bucket entry, or entire bucket)
  """
  def expire_activity(activity, time) do

    Process.send_after(:activity_expire, {:expire_activity, activity}, time)
  end


  # Server
  ###########################

  def handle_info({:expire_activity, activity}, state) do

    Activity.remove_item(activity)

    {:noreply, state - 1}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end