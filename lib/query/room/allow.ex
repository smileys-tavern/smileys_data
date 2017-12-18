defmodule SmileysData.Query.Room.Allow do

  require Ecto.Query

  alias SmileysData.{UserRoomAllow, Repo}

  @doc """
  Return a row indicating permission of a user to post in a room
  """
  def user_allowed(user_name, room_name) do
    case UserRoomAllow |> Repo.get_by(username: user_name, roomname: room_name) do
      nil ->
        {:user_not_allowed, nil}
      permission ->
        {:ok, permission}
    end
  end

  @doc """
  Get the user room allow record by id
  """
  def by_id(user_room_allow_id) do
    UserRoomAllow |> Repo.get!(user_room_allow_id)
  end

  @doc """
  Add a record allowing a user in room
  """
  def create(%UserRoomAllow{} = changeset) do
    Repo.insert(changeset)
  end

  @doc """
  Remove a record allowing a user in room
  """
  def user_room_allow_delete(user_room_allow_record) do
    Repo.delete!(user_room_allow_record)
  end

  @doc """
  Return a list of users, paginated, that have permission to post in a room
  """
  def user_list(room_name, request_params) do
    UserRoomAllow |> Ecto.Query.where(roomname: ^room_name) |> Repo.paginate(request_params)
  end
end