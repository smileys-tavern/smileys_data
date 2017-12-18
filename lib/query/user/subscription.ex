defmodule SmileysData.Query.User.Subscription do

  require Ecto.Query

  alias SmileysData.{Repo, User, UserSubscription, UserRoomAllow}

  @doc """
  Create a single user subscription to the passed room and pass tuple {:ok, subscription} on success
  """
  def create(user, room) do
    if user do
      allSubscriptions = UserSubscription |> Ecto.Query.where(userid: ^user.id) |> Repo.all

      if length(allSubscriptions) >= 15 do
        {:subscriptions_full, nil}
      else
        changeset = UserSubscription.changeset(%UserSubscription{}, %{"userid" => user.id, "roomname" => room.name, "type" => "sub"})

        Repo.insert(changeset)
      end
    else
      {:no_user, nil}
    end
  end

  @doc """
  Remove a single user subscription from the given room by room name
  """
  def delete(user, room_name) do
    if user do
      subscription = UserSubscription |> Repo.get_by(userid: user.id, roomname: room_name)

      subscription_repo = Repo.get!(UserSubscription, subscription.id)

      Repo.delete!(subscription_repo)

      {:ok, room_name}
    else
      {:no_user, nil}
    end
  end

  @doc """
  Return a users subscription to a room, if such exists
  Old version: user_to_room
  """
  def room_by_id(user_id, room_name) do
    case UserSubscription |> Repo.get_by(userid: user_id, roomname: room_name) do
      nil ->
        {:no_subscription, nil}
      subscription ->
        {:ok, subscription}
    end
  end

  @doc """
  Return all of a users subscriptions if the user is valid
  Old: user_subscriptions
  """
  def get(user) do
    case user do
      nil ->
        []
      _ ->
        UserSubscription |> Ecto.Query.where(userid: ^user.id) |> Repo.all
    end
  end

  @doc """
  Checks whether a user is eligible to subscribe to a room
  """
  def can_subscribe_to_room(user, room) do
    if !user || !room do
      false
    else
      # if already subscribed
      isSubscribed = case UserSubscription |> Repo.get_by(userid: user.id, roomname: room.name) do
        nil ->
          false
        _ ->
          true
      end

      if isSubscribed do
        false
      else
        case room.type do
          "public" ->
            true
          "private" ->
            case UserRoomAllow |> Repo.get_by(username: user.name, roomname: room.name) do
              nil ->
                false
              _ ->
                true
            end
          "restricted" ->
            true
          "house" ->
            false
        end
      end
    end
  end

  @doc """
  Return the relevant fields for a set of users queried by the given subscription type.
  """
  def by_email_subscription_type(subscription_type) do
    User 
      |> Ecto.Query.select([:id, :email, :name, :drinks])
      |> Ecto.Query.where(subscription_email: ^subscription_type)
      |> Repo.all
  end

  @doc """
  Update the users subscription setting
  """
  def update_email(%User{} = user, subscription_setting) do
    changeset = User.changeset(user, %{"subscription_email" => subscription_setting})

    Repo.update(changeset)
  end
end