defmodule SmileysData.QueryUser do

  require Ecto.Query

  alias SmileysData.{User, ModeratorListing, Repo}

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
    User |> Repo.get(user_id)
  end

  @doc """
  Return the relevant fields for a set of users queried by the given subscription type.
  """
  def users_by_email_subscription_type(subscription_type) do
    User 
      |> Ecto.Query.select([:id, :email, :name, :drinks])
      |> Ecto.Query.where(subscription_email: ^subscription_type)
      |> Repo.all
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

  @doc """
  Call this when voting on and against original content
  TODO: move most of the logic 
  """
  def update_user_reputation(post, adjustValue) do
    cond do
      adjustValue >= 0 ->
        Ecto.Query.from(u in User, 
          where: u.id == ^post.posterid, where: u.reputation < 100, 
          update: [inc: [reputation: ^adjustValue]]
        ) |> Repo.update_all([])
      true ->
        Ecto.Query.from(u in User, 
          where: u.id == ^post.posterid, where: u.reputation > 0, 
          update: [inc: [reputation: ^adjustValue]]
        ) |> Repo.update_all([])
    end
  end

  @doc """
  Update the users subscription setting
  """
  def update_user_email_subscription(user, subscription_setting) do
    changeset = User.changeset(user, %{"subscription_email" => subscription_setting})

    Repo.update(changeset)
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