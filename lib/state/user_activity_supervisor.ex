defmodule SmileysData.State.UserActivitySupervisor do
  use Supervisor

  def start_link do
  	Supervisor.start_link(__MODULE__, nil, name: :user_activity_supervisor)
  end

  @doc """
  Start an activity child which can be any kind of activity server
  """
  def start_child(name) do
    Supervisor.start_child(:user_activity_supervisor, [name])
  end

  def init(_) do
    supervise([worker(SmileysData.State.User.ActivityBucket, [])], strategy: :simple_one_for_one)
  end
end