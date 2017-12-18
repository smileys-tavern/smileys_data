defmodule SmileysData.Query.Room do
	
  require Ecto.Query

  alias SmileysData.{Room, Repo}

  @doc """
  Return all room model data after querying for it by name
  """
  def by_name(name) do
    Room |> Repo.get_by(name: name)
  end

  @doc """
  Return all room model data querying by id
  """
  def by_id(id) do
    Room |> Repo.get_by(id: id)
  end

  @doc """
  Return a list of publicly available rooms ordered by reputation or date
  """
  def list(order_by, limit) do
    Room 
      |> Ecto.Query.where([r], r.type == "public" or r.type == "restricted") 
      |> Ecto.Query.limit(^limit)
      |> Ecto.Query.order_by(desc: ^order_by) 
      |> Repo.all
  end

  @doc """
  Adjust the reputation of an entire room (the room value, not the users therein)
  """
  def update_reputation(%Room{} = room, adjustValue) do
    Ecto.Query.from(r in Room, 
      where: r.id == ^room.id, 
      update: [inc: [reputation: ^adjustValue]]
    ) |> Repo.update_all([])
  end

  @doc """
  Create a room given a changeset
  """
  def create(%Room{} = changeset) do
    Repo.insert(changeset)
  end

  @doc """
  Update a room via changeset
  """
  def update(%Room{} = changeset) do
    Repo.update(changeset)
  end
end