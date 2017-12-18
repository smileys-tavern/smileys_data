defmodule SmileysData.Query.User.Moderator do
  
  require Ecto.Query

  alias SmileysData.{Repo, ModeratorListing, User}

  @doc """
  Update the users moderation list
  """
  def update_rooms(user, moderating) do
    changeset = User.changeset(user, %{"moderating" => moderating})

    Repo.update(changeset)
  end

  @doc """
  Add a user as a moderator to a room
  """
  def add(changeset) do
    Repo.insert(changeset)
  end

  @doc """
  Grant moderator power to the given user for the given room
  Old v: create_user_moderator_privalege
  """
  def create_room_privalege(user, room, privilege) do
    changeset = ModeratorListing.changeset(%ModeratorListing{}, %{"userid" => user.id, "roomid" => room.id, "type" => privilege})

    case Repo.insert(changeset) do
      {:ok, _moderatorlisting} ->
        current_user_w_moderation = build_rooms(user)

        # update user with moderation list
        update_rooms(user, current_user_w_moderation.moderating)

      _ ->
        {:ok, user}
    end
  end

  @doc """
  Return a list of usernames and permissions associated with the given room
  Old v: moderators_for_room
  """
  def moderators_for_room(room_id, request_params) do
    ModeratorListing 
      |> Ecto.Query.join(:left, [ml], u in User, u.id == ml.userid)
      |> Ecto.Query.where(roomid: ^room_id)
      |> Ecto.Query.select([ml, u], %{username: u.name, type: ml.type})
      |> Repo.paginate(request_params)
  end

  @doc """
  Use the moderator listing model to build a map of rooms by id the passed user is moderating, and build up
  the User with that information.
  Old version: build_user_moderator_rooms
  """
  def build_rooms(user) do
    case ModeratorListing |> Ecto.Query.where(userid: ^user.id) |> Repo.all do
      nil ->
        Map.put(user, :moderating, %{})
      moderating ->
        # change to string keys to support postgres storage of jsonb
        moderatingRooms = Enum.map moderating, fn(moderator_row) ->
          %{Integer.to_string(moderator_row.roomid) => moderator_row.type}
        end

        Map.put(user, :moderating, moderatingRooms)
    end
  end

  @doc """
  Get a moderator listing row if it exists for the user in the given room
  Old version: user_room_moderator_listing
  """
  def by_room_id(user_id, room_id) do
    ModeratorListing |> Repo.get_by(userid: user_id, roomid: room_id)
  end

  @doc """
  Retreive a moderator listing entry by its id
  """
  def by_id(moderator_listing_id) do
    ModeratorListing |> Repo.get!(moderator_listing_id)
  end

  @doc """
  Delete a moderator listing
  """
  def delete(%ModeratorListing{} = moderator_listing_repo) do
    Repo.delete!(moderator_listing_repo)
  end

  @doc """
  Returns true if user is moderator of a room, or false elsewise
  """
  def moderating_room(%{:moderating => moderating} = _user, roomid) do
    moderating_room(moderating, roomid)
  end

  def moderating_room([], _roomid) do
    false
  end

  def moderating_room([moderatingRoom | tail], roomid) do
    # string keys to support postgres storage of json
    if Map.has_key?(moderatingRoom, Integer.to_string(roomid)) do
      moderatingRoom[Integer.to_string(roomid)]
    else
      moderating_room(tail, roomid)
    end
  end
end