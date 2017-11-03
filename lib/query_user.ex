defmodule SmileysData.QueryUser do

  require Ecto.Query

  alias SmileysData.{User, Vote, ModeratorListing, Repo}

  @doc """
  Return full user data after querying by email
  """
  def user_by_email(email) do
    User |> Repo.get_by(email: email)
  end

  @doc """
  Return full user data after querying by name
  """
  def user_by_name(user_name) do
    User |> Repo.get_by(name: user_name)
  end

  @doc """
  Return full user data after querying by id
  """
  def user_by_id(user_id) do
    Repo.get(User, user_id)
  end

  @doc """
  Use the moderator listing model to build a map of rooms by id the passed user is moderating, and build up
  the User with that information.
  """
  def build_user_moderator_rooms(user) do
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
  """
  def user_room_moderator_listing(user_id, room_id) do
    ModeratorListing |> Repo.get_by(userid: user_id, roomid: room_id)
  end

  @doc """
  Retreive a moderator listing entry by its id
  """
  def moderator_listing_by_id(moderator_listing_id) do
    ModeratorListing |> Repo.get!(moderator_listing_id)
  end

  def moderator_listing_delete(moderator_listing_repo) do
    Repo.delete!(moderator_listing_repo)
  end

  @doc """
  Update the users moderation list
  """
  def update_user_moderator_rooms(user, moderating) do
    changeset = User.changeset(user, %{"moderating" => moderating})

    Repo.update(changeset)
  end

  @doc """
  Add a user as a moderator to a room
  """
  def user_moderator_add(changeset) do
    Repo.insert(changeset)
  end

  @doc """
  Grant moderator power to the given user for the given room
  """
  def create_user_moderator_privalege(user, room, privilege) do
    changeset = ModeratorListing.changeset(%ModeratorListing{}, %{"userid" => user.id, "roomid" => room.id, "type" => privilege})

    case Repo.insert(changeset) do
      {:ok, _moderatorlisting} ->
        current_user_w_moderation = build_user_moderator_rooms(user)

        # update user with moderation list
        update_user_moderator_rooms(user, current_user_w_moderation.moderating)

      _ ->
        {:ok, user}
    end
  end

  @doc """
  Return a list of usernames and permissions associated with the given room
  """
  def moderators_for_room(room_id, request_params) do
    ModeratorListing 
      |> Ecto.Query.join(:left, [ml], u in User, u.id == ml.userid)
      |> Ecto.Query.where(roomid: ^room_id)
      |> Ecto.Query.select([ml, u], %{username: u.name, type: ml.type})
      |> Repo.paginate(request_params)
  end

  def update_user_reputation(post, user, room, modifier) do
    amountAdjust = cond do
      room.reputation > 0 && SmileysData.QueryRoom.room_is_moderator(user.moderating, room.id) ->
        2
      user.reputation >= 30 ->
        1
      true ->
        0
    end

    if amountAdjust > 0 do
      # TODO: move to vote query
      votes = Vote |> Ecto.Query.where(postid: ^post.id) |> Repo.all

      for vote <- votes do
        # if poster did opposite of what reputable voter did, reverse adjustment
        finalAdjust = cond do
          modifier > 0 && vote.vote < 0 ->
            amountAdjust * -1
          modifier < 0 && vote.vote > 0 ->
            amountAdjust * -1
          true ->
            amountAdjust
        end

        # max rep 51
        if (user.name != vote.username) do
          Ecto.Query.from(u in User, 
            where: u.name == ^vote.username, where: u.reputation < 51, where: u.reputation > 0, 
            update: [inc: [reputation: ^finalAdjust]]
          )
            |> Repo.update_all([])
        end
      end
    end
  end

  @doc """
  Return the permission set that applies to the passed User
  """
  def user_permission_level(_user) do
    %{default: Guardian.Permissions.max}
  end

  def create_hash(user_ip) do
    s = Hashids.new([
      salt: "smileysuser-mystery",
      min_len: 6,
    ])

    Hashids.encode(s, Tuple.to_list(user_ip))
  end
end