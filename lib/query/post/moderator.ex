defmodule SmileysData.Query.Post.Moderator do
  require Ecto.Query

  alias SmileysData.{Post, Room, PostMeta, QueryRoom, Repo}

  @doc """
  Edit a comment based on a moderator action.
  """
  def edit(op, user) do
    changeset = Post.changeset(op, %{"body" => String.replace(@delete_msg, "?", user.name), "posterid" => user.id})

    Repo.update(changeset)
  end

  @doc """
  Soft delete a post by overwriting it. This is by moderator
  """
  def delete(user, hash, depth, op_hash, mod_comment) do
    if !user do
      {:no_user, nil}
    else
      op    = Post |> Repo.get_by(hash: hash)
      room  = Room |> Repo.get_by(id: op.superparentid)

      case QueryRoom.room_is_moderator(user.moderating, room.id) do
        false ->
          {:not_mod, nil}
        _type_mod ->
          editedComment = case edit_post_by_moderator(op, user) do
            {:ok, edited_comment} ->
              edited_comment
            _ ->
              nil
          end

          newComment = case create_comment(hash, op_hash, mod_comment, depth, user) do
            {:ok, created_comment} ->
              created_comment
            _ ->
              nil
          end

          case newComment && editedComment do
            nil ->
              {:error, nil}
            _ ->
              Ecto.Query.from(p in PostMeta, where: p.postid == ^op.id) |> Repo.delete_all

              {:ok, %{:edited => editedComment, :new => newComment}}
          end
      end
    end
  end
end