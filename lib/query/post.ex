defmodule SmileysData.Query.Post do
  require Ecto.Query

  alias SmileysData.{Post, AnonymousPost, Room, Comment, PostMeta, User, Repo}

  @thread_query_max 50
  @thread_query_focus_max 100

  # TODO: Better of this is extracted out of data and more into the web/display code/gettext
  @delete_msg "Deleted by moderator ?"
  @edit_msg "(edit) ?"

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
    latest_by_user(user, limit, true)
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

      case is_post_frequency_limit(user) do
        false ->
          # insert post
          case Repo.insert(changeset) do
            {:ok, post} ->
              # auto-upvote it if not an anonymous post
              if (user.id != Application.get_env(:smileys, :mysteryuser)) do
                SmileysData.QueryVote.upvote(post, user)
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

  @doc """
  Return whether the post frequency time is violated and handle cases where a user has not posted or user
  not provided.
  """
  def is_post_frequency_limit(user) do
    case user do
      nil ->
        false
      _ ->
        # If post limit isnt configured, there will be no limitations
        post_limits = String.split(Application.get_env(:smileysdata, :post_limits), ",")

        seconds_since_last_post = case get_seconds_since_last_post(user) do
          {:ok, :no_posts} ->
            :ok
          {:ok, seconds} ->
            {seconds_since, _} = Integer.parse(seconds)
            seconds_since
          _ ->
            nil
        end

        check_post_frequency_conditions(user, seconds_since_last_post, post_limits)
    end
  end

  @doc """
  Create a unique hash for a post
  """
  def create_hash(userid, room_name) do
    s = Hashids.new([
      salt: "smileystavern-" <> room_name,
      min_len: 6,
    ])

    {_, _, micro} = :os.timestamp

    Hashids.encode(s, [micro, userid])
  end

  @doc """
  Return the number of seconds since the given users last post
  """
  def get_seconds_since_last_post(user) do
  	{from, where} = case user do
  		nil ->
  			{nil, nil}
  		%{user_token: user_token} ->
  			{"anonymousposts", "hash = '" <> user_token <> "'"}
  		_ ->
  			{"posts", "posterid = " <> Integer.to_string(user.id)}
  	end


    query_string = case from do
      nil -> 
        {:error, "no user"}
      _ ->
        # note: unsafe query, only internal functions should access
        {:ok, "
          SELECT to_char(
            float8 (
              extract(epoch from NOW() - INTERVAL '8 hours') - 
              extract(epoch from inserted_at - INTERVAL '8 hours')
            ), 'FM999999999999999999'
            ) AS time_since_last_post
          FROM " <> from <> "
          WHERE " <> where <> "
          ORDER BY inserted_at DESC
          LIMIT 1
        "}
    end

    case query_string do
      {:ok, query} ->
        res = Ecto.Adapters.SQL.query!(Repo, query, [])

        cols = Enum.map res.columns, &(String.to_atom(&1))

        result = Enum.map res.rows, fn(row) ->
          Enum.zip(cols, row)
        end

        case List.first(result) do
          nil ->
            {:ok, :no_posts}
          post_row ->
            {:ok, post_row[:time_since_last_post]}
        end
      error ->
        error
    end
  end

  defp check_post_frequency_conditions(_, _, false) do
  	false
  end

  defp check_post_frequency_conditions(_, :ok, _) do
  	# Never posted case
  	false
  end

  defp check_post_frequency_conditions(_, nil, _) do
  	true
  end

  defp check_post_frequency_conditions(user, seconds_since_last_post, post_limits) do
  	get_post_frequency_user_limit(user, post_limits)
  end

  defp get_post_frequency_user_limit(user_reputation, post_limits) do
  	post_limit_i = cond do
  		user_reputation >= @max_reputation ->
  			3
  		user_reputation >= @strong_reputation ->
  			2
  		user_reputation >= @good_reputation ->
  			1
  		_ ->
  			0 
    end

    limit = String.to_integer(Enum.at(post_limits, post_limit_i)

    if (seconds_since_last_post > limit) do
    	false
    else
    	limit
    end
  end
end