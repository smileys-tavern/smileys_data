defmodule SmileysData.QueryRoom do

  require Ecto.Query

  alias SmileysData.{Room, Repo}

  @doc """
  Return all room model data after querying for it by name
  """
  def room(name) do
    Room |> Repo.get_by(name: name)
  end

  @doc """
  Return all room model data querying by id
  """
  def room_by_id(id) do
    Room |> Repo.get_by(id: id)
  end

  @doc """
  Return a list of publicly available rooms ordered by reputation or date
  """
  def list_by(order_by, limit) do
    Room 
      |> Ecto.Query.where([r], r.type == "public" or r.type == "restricted") 
      |> Ecto.Query.limit(^limit)
      |> Ecto.Query.order_by(desc: ^order_by) 
      |> Repo.all
  end

  @doc """
  Adjust the reputation of an entire room (the room value, not the users therein)
  """
  def update_room_reputation(user, room, modifier) do
    amountAdjust = cond do
      user.reputation >= 45 ->
        1
      true ->
        0
    end

    if amountAdjust > 0 do
        # if poster did opposite of what reputable voter did, reverse adjustment
        finalAdjust = modifier * amountAdjust

        Ecto.Query.from(r in Room, 
          where: r.id == ^room.id, 
          update: [inc: [reputation: ^finalAdjust]]
        ) |> Repo.update_all([])
    end
  end

  @doc """
  Create a room given a changeset
  """
  def room_create(changeset) do
    Repo.insert(changeset)
  end

  @doc """
  Update a room via changeset
  """
  def room_update(changeset) do
    Repo.update(changeset)
  end

  @doc """
  Returns true if user is moderator of a room, or false elsewise
  """
  def room_is_moderator(%{:moderating => moderating} = _user, roomid) do
    room_is_moderator(moderating, roomid)
  end

  def room_is_moderator([], _roomid) do
    false
  end

  def room_is_moderator([moderatingRoom | tail], roomid) do
    # string keys to support postgres storage of json
    if Map.has_key?(moderatingRoom, Integer.to_string(roomid)) do
      moderatingRoom[Integer.to_string(roomid)]
    else
      room_is_moderator(tail, roomid)
    end
  end
end