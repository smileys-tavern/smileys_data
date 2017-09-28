defmodule SmileysData.QueryPost do

  require Ecto.Query


  alias SmileysData.{Post, Room, Comment, PostMeta, User, Repo}

  @doc """
  Retrieve post specific data via hash key
  """
  def post_by_hash(hash) do
    Post |> Repo.get_by(hash: hash)
  end

  @doc """
  Retrieve post specific data via id
  """
  def post_by_id(id) do
    Post |> Repo.get!(id)
  end

  @doc """
  Return enough post data to show a summary of the post. No room specified
  """
  def summary(limit) do
    summary(limit, :vote, :nil)
  end

  def summary(limit, order_by) do
    summary(limit, order_by, :nil)
  end

  def summary(limit, order_by, room_id) do
    summary(limit, order_by, room_id, %{}, false)
  end

  def summary(limit, order_by, room_id, request_params, show_private) do
    post = Post
      |> Ecto.Query.join(:left, [p], u in User, u.id == p.posterid)
      |> Ecto.Query.join(:left, [p], pm in PostMeta, p.id == pm.postid)
      |> Ecto.Query.join(:left, [p], r in Room, p.superparentid == r.id)
      |> Ecto.Query.select([p, u, pm, r], %{id: p.id, title: p.title, hash: p.hash, posterid: p.posterid, votepublic: p.votepublic, parenttype: p.parenttype, name: u.name, thumb: pm.thumb, link: pm.link, tags: pm.tags, roomname: r.name})
      |> Ecto.Query.where(parenttype: "room")
      |> Ecto.Query.limit(^limit)

    post_with_order = case order_by do
      :alltime ->
        post
          |> Ecto.Query.order_by([p], desc: p.votealltime)
      :vote ->
        post
          |> Ecto.Query.order_by([p], desc: p.voteprivate)
      :new ->
        post
          |> Ecto.Query.order_by(desc: :inserted_at)
      _ ->
        post
          |> Ecto.Query.order_by([p], desc: p.voteprivate)
    end

    post_room_constraint = case room_id do
      :nil ->
        post_with_order
      _ ->
        post_with_order
          |> Ecto.Query.where(parentid: ^room_id) 
    end

    post_with_private = cond do
      !show_private ->
        post_room_constraint
          |> Ecto.Query.where([p, u, pm, r], r.type != "private")
      true ->
        post_room_constraint
    end

    post_with_private
      |> Repo.paginate(request_params)
  end

  @doc """
  Return enough post data to summarize posts, queried by specific room
  """
  def summary_by_room(limit, order_by, room_id, request_params) do
    summary(limit, order_by, room_id, request_params, true)
  end

  @doc """
  Soft delete a post by overwriting it. This is by moderator
  """
  def delete_post_by_moderator(user, hash, depth, op_hash, mod_comment) do
    if !user do
      {:no_user, nil}
    else
      op    = Post |> Repo.get_by(hash: hash)
      room  = Room |> Repo.get_by(id: op.superparentid)

      case SmileysData.QueryRoom.room_is_moderator(user.moderating, room.id) do
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

  @doc """
  Retrieve a thread of comments complete with the level the comment exists at in the chain
  """
  def get_thread(mode, post_id) do
    query_modifier = case mode do
      "new" ->
        "p.id * -1"
      _ ->
        "p.voteprivate * -1"
    end

    limit = case mode do
      "focus" ->
        "100"
      _ ->
        "50"
    end

    qry = "
      WITH RECURSIVE posts_r(id, posterid, superparentid, parentid, parenttype, body, age, hash, votepublic, voteprivate, inserted_at, depth, path) AS (
            SELECT p.id, p.posterid, p.superparentid, p.parentid, p.parenttype, body, age, hash, votepublic, voteprivate, 
              inserted_at, 1, ARRAY[" <> query_modifier <> ", p.id]
            FROM posts p
            WHERE p.parentid = " <> Integer.to_string(post_id) <> " AND p.parenttype != 'room'
          UNION ALL
            SELECT p.id, p.posterid, p.superparentid, p.parentid, p.parenttype, p.body, p.age, p.hash, p.votepublic, p.voteprivate, 
              p.inserted_at, pr.depth + 1, path || " <> query_modifier <> " || p.id
            FROM posts p, posts_r pr
          WHERE p.parentid = pr.id AND p.parenttype != 'room'
      )
      SELECT psr.id, psr.posterid, psr.superparentid, psr.parentid, psr.parenttype, psr.body, psr.age, psr.hash, psr.votepublic, 
        psr.voteprivate, psr.inserted_at, psr.depth, psr.path, u.name
      FROM posts_r psr LEFT JOIN users u ON psr.posterid = u.id 
      ORDER BY path LIMIT " <> limit <> "
    "

    res = Ecto.Adapters.SQL.query!(Repo, qry, [])

    cols = Enum.map res.columns, &(String.to_atom(&1))

    comments = Enum.map res.rows, fn(row) ->
      struct(Comment, Enum.zip(cols, row))
    end

    comments
  end

  @doc """
  Edit a comment based on a moderator action.
  """
  def edit_post_by_moderator(op, user) do
    changeset = Post.changeset(op, %{"body" => "Deleted by moderator " <> user.name, "posterid" => user.id})

    Repo.update(changeset)
  end

  @doc """
  Edit a post owned by the user
  """
  def edit_comment(hash, body, user) do
    op = Post |> Repo.get_by(hash: hash)

    if op.posterid != user.id do
      nil
    else
      changeset = Post.changeset(op, %{"body" => "(edit) " <> body})

      case Repo.update(changeset) do
        {:ok, post} ->
          post
        {:error, _changeset} ->
          nil
      end
    end
  end

  @doc """
  Create a comment
  """
  def create_comment(replyToHash, opHash, body, depth, user) do
    op = Post |> Repo.get_by(hash: opHash)
    replyToPost = Post |> Repo.get_by(hash: replyToHash)
    room = Room |> Repo.get_by(id: op.superparentid)

    if is_post_frequency_limit(user) do
      {:post_frequency_violation, nil}
    else
      changeset = Post.changeset(%Post{}, %{
        "body" => body, 
        "title" => "reply", 
        "superparentid" => room.id,
        "parentid" => replyToPost.id, 
        "parenttype" => "comment",
        "posterid" => user.id,
        "age" => 0,
        "hash" => create_hash(user.id, room.name),
        "votepublic" => 0,
        "voteprivate" => user.reputation,
        "votealltime" => user.reputation,
        "ophash" => opHash
      })

      cond do
        validate_post_body(body) ->
          case Repo.insert(changeset) do
            {:ok, post} ->
              if (user.name != "amysteriousstranger") do
                SmileysData.QueryVote.upvote(post, user)

                post = put_in post.votepublic, 1

                {:ok, %{:comment => Map.merge(post, %{:depth => (depth + 1), :name => user.name}), :room => room, :op => op}}
              else
                {:ok, %{:comment => Map.merge(post, %{:depth => (depth + 1), :name => user.name}), :room => room, :op => op}}
              end
            {:error, changeset} ->
              {:error, changeset}
          end
        true ->
          {:body_invalid, nil}
      end
    end
  end

  @doc """
  Retrieve the latest posts a user made
  """
  def latest_by_user(user, limit) do
    latest_by_user(user, limit, true)
  end

  def latest_by_user(user, limit, include_private) do
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
  def create_new_post(user, request_params, meta_params, image_upload) do
    Repo.transaction fn ->
      # Meta tags modify the body with templates. Check for them here

      changeset = Post.changeset(%Post{}, request_params)

      if is_post_frequency_limit(user) do
        {:post_frequency_violation, nil}
      end

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
    end
  end

  @doc """
  Get post summaries by a list of post id's.
  """
  def post_summary_by_ids(ids) do
    post_summary_by_ids(ids, [])
  end

  def post_summary_by_ids([], acc) do
    acc
  end

  def post_summary_by_ids([id | tail], acc) do
    post_summary_by_ids(tail, [query_post_summary_by_id(id)|acc])
  end

  @doc """
  Return the number of seconds since the given users last post
  """
  def get_seconds_since_last_post(user) do
    case user do
      nil -> 
        {:error, "no user"}
      _ ->
        qry = "
          SELECT to_char(
            float8 (
              extract(epoch from NOW() - INTERVAL '8 hours') - 
              extract(epoch from inserted_at - INTERVAL '8 hours')
            ), 'FM999999999999999999'
            ) AS time_since_last_post
          FROM posts
          WHERE posterid = " <> Integer.to_string(user.id) <> "
          ORDER BY inserted_at DESC
          LIMIT 1
        "

        res = Ecto.Adapters.SQL.query!(Repo, qry, [])

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
    end
  end

  @doc """
  Lower private vote value for posts that fall within an upper and lower time bound by the given
  ratio.
  """
  def decay_posts(ratio, interval1, interval2) do
    qry = "
      UPDATE posts SET voteprivate = (voteprivate - ROUND(voteprivate * " <> ratio <> "))
      WHERE (inserted_at - INTERVAL '8 hours', inserted_at - INTERVAL '8 hours') 
        OVERLAPS (CURRENT_TIMESTAMP - " <> interval1 <> ", CURRENT_TIMESTAMP - " <> interval2 <> ");
    "

    case Ecto.Adapters.SQL.query(Repo, qry, []) do
      {:ok, result} ->
        %{num_rows: rows} = result
        {:ok, rows}
        rows
      _ ->
        {:error, 0}
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

        result = cond do
          !post_limits ->
            false
          length(post_limits) != 4 ->
            false
          seconds_since_last_post == :ok ->
            false
          !seconds_since_last_post ->
            true
          # TODO: make reputation limits configurable
          user.reputation >= 50 ->
            case post_limits do
              [_,_,_,limit] ->
                cond do
                  seconds_since_last_post > String.to_integer(limit) ->
                    false
                  true ->
                    true
                end
              _ ->
                false
            end
          user.reputation >= 30 ->
            case post_limits do
              [_,_,limit,_] ->
                cond do
                  seconds_since_last_post > String.to_integer(limit) ->
                    false
                  true ->
                    true
                end
              _ ->
                false
            end
          user.reputation >= 20 ->
            case post_limits do
              [_,limit,_,_] ->
                cond do
                  seconds_since_last_post > String.to_integer(limit) ->
                    false
                  true ->
                    true
                end
              _ ->
                false
            end
          user.reputation >= 0 ->
            case post_limits do
              [limit,_,_,_] ->
                cond do
                  seconds_since_last_post > String.to_integer(limit) ->
                    false
                  true ->
                    true
                end
              _ ->
                false
            end
          true ->
            true
        end

        result
    end
  end

  defp query_post_summary_by_id(id) do
    # I will return when a good deploy strat is available for mnesia or alternative cache implemented
    # postSummary = Amnesia.transaction do
    #  DbSmileyCache.PostSummary.read(id)
    #end

    post_summary = nil

    case post_summary do
      [post_summary_from_cache|_] ->
        post_summary_from_cache
      _ ->
        post = Post
          |> Ecto.Query.join(:left, [p], u in User, u.id == p.posterid)
          |> Ecto.Query.join(:left, [p], pm in PostMeta, p.id == pm.postid)
          |> Ecto.Query.join(:left, [p], r in Room, p.superparentid == r.id)
          |> Ecto.Query.select([p, u, pm, r], %{title: p.title, body: p.body, hash: p.hash, votepublic: p.votepublic, parenttype: p.parenttype, name: u.name, thumb: pm.thumb, link: pm.link, imageurl: pm.image, tags: pm.tags, roomname: r.name})
          |> Repo.get_by(id: id)

        post_with_url = Map.put_new(post, :posturl, create_post_url(post))

        post_with_body_sample = %{post_with_url | :body => String.slice(HtmlSanitizeEx.strip_tags(post.body), 0..80)}

          # I will return when a good deploy strategy is employed for mnesia or alternative cache implemented
          #Amnesia.transaction do
          #  _result = %DbSmileyCache.PostSummary{...} |> DbSmileyCache.PostSummary.write
          #end
        post_with_body_sample
    end 
  end

  defp create_post_url(post_row) do
    ophash = cond do
      Map.has_key?(post_row, :hash) ->
        post_row.hash
      true ->
        ""
    end

    case post_row.parenttype do
      "room" ->
        "/r/" <> post_row.roomname <> "/comments/" <> post_row.hash <> "/" <> post_row.title
      _ ->
        "/r/" <> post_row.roomname <> "/comments/" <> ophash <> "/focus/" <> post_row.hash
    end
  end

  @doc """
  Validate that the body of the post stays to the required characters
  """
  def validate_post_body(body) do
    String.match?(body, ~r/^[a-zA-Z0-9 \s.,?!:;\-"'\[\])(}{#%=*\^\/_]+$/)
  end

  def create_hash(userid, room_name) do
    s = Hashids.new([
      salt: "smileystavern-" <> room_name,
      min_len: 6,
    ])

    {_, _, micro} = :os.timestamp

    Hashids.encode(s, [micro, userid])
  end
end