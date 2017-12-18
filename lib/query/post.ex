defmodule SmileysData.Query.Post do
  require Ecto.Query

  alias SmileysData.{Post, Room, PostMeta, User, Repo}
  alias SmileysData.Query.Post.Helper
  alias SmileysData.Query.Vote, as: QueryVote

  @doc """
  Retrieve post specific data via hash key
  """
  def by_hash(hash) do
    Post |> Repo.get_by(hash: hash)
  end

  @doc """
  Retrieve post specific data via id
  """
  def by_id(id) do
    Post |> Repo.get!(id)
  end

  @doc """
  Retrieve the latest posts a user made
  """
  def by_user_latest(%User{} = user, limit) do
    by_user_latest(user, limit, true)
  end

  def by_user_latest(%User{} = user, limit, include_private) do
    case user do
      nil -> 
        []
      _ -> 
        post_query = Post
          |> Ecto.Query.join(:left, [p], r in Room, p.superparentid == r.id)
          |> Ecto.Query.select([p, r], %{title: p.title, votepublic: p.votepublic, hash: p.hash, parenttype: p.parenttype, roomname: r.name, ophash: p.ophash})
          |> Ecto.Query.where(posterid: ^user.id)
          |> Ecto.Query.order_by([p], desc: p.updated_at)
          |> Ecto.Query.limit(^limit)

        cond do 
          include_private ->
            post_query
              |> Repo.all
          true ->
            post_query
              |> Ecto.Query.where([p, r], r.type != "private")
              |> Repo.all
        end
    end
  end

  @doc """
  Transaction that creates a post and its meta data
  """
  def create_new(user, request_params, meta_params, image_upload) do
    Repo.transaction fn ->
      # Meta tags modify the body with templates. Check for them here

      changeset = Post.changeset(%Post{}, request_params)

      case Helper.is_post_frequency_limit(user) do
        false ->
          # insert post
          case Repo.insert(changeset) do
            {:ok, post} ->
              # auto-upvote it if not an anonymous post
              if (user.id != Application.get_env(:smileys, :mysteryuser)) do
                QueryVote.up(post, user)
              end

              _result = cond do
                image_upload ->
                  changeset_meta = PostMeta.changeset(%PostMeta{}, %{"userid" => user.id, "postid" => post.id, "thumb" => image_upload[:thumb],
                    "tags" => meta_params["tags"], "image" => image_upload[:image], "link" => meta_params["link"]})

                  # insert post meta
                  Repo.insert!(changeset_meta)

                String.length(meta_params["link"]) > 0 || String.length(meta_params["tags"]) > 0 ->
                  changeset_meta = PostMeta.changeset(%PostMeta{}, %{"userid" => user.id, "postid" => post.id, "tags" => meta_params["tags"], "link" => meta_params["link"]})

                  Repo.insert!(changeset_meta)
                    
                true ->
                  nil
              end
            
              {:ok, post}
            {:error, changeset} ->
              {:error, changeset}
          end
        limit ->
          {:post_frequency_violation, limit}
      end
    end
  end
end