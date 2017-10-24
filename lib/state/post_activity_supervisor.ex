defmodule SmileysData.State.PostActivitySupervisor do
  use Supervisor

  def start_link do
  	Supervisor.start_link(__MODULE__, nil, name: :post_activity_supervisor)
  end

  @doc """
  Start an activity child which can be any kind of activity server
  """
  def start_child(name) do
    Supervisor.start_child(:post_activity_supervisor, [name])
  end

  def init(_) do
    supervise([worker(SmileysData.State.Post.ActivityBucket, [])], strategy: :simple_one_for_one)
  end
end