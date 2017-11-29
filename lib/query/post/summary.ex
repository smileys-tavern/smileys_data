defmodule SmileysData.Query.Post.Summary do
  require Ecto.Query

  alias SmileysData.{Post, Room, PostMeta, User, Repo}

  @summary_body_preview_length 80

  @doc """
  Return enough post data to show a summary of the post. No room specified
  """
  def get(limit) do
    summary(limit, :vote, :nil)
  end

  def get(limit, order_by) do
    summary(limit, order_by, :nil)
  end

  def get(limit, order_by, room_id) do
    summary(limit, order_by, room_id, %{}, false)
  end

  def get(limit, order_by, room_id, request_params, show_private) do
    post = Post
      |> Ecto.Query.join(:left, [p], u in User, u.id == p.posterid)
      |> Ecto.Query.join(:left, [p], pm in PostMeta, p.id == pm.postid)
      |> Ecto.Query.join(:left, [p], r in Room, p.superparentid == r.id)
      |> Ecto.Query.select([p, u, pm, r], %{id: p.id, title: p.title, hash: p.hash, posterid: p.posterid, votepublic: p.votepublic, parenttype: p.parenttype, name: u.name, thumb: pm.thumb, link: pm.link, tags: pm.tags, roomname: r.name})
      |> Ecto.Query.where(parenttype: "room")
      |> Ecto.Query.limit(^limit)
      |> add_room_id_to_query(room_id)
      |> add_order_by_to_query(order_by)
      |> query_check_for_privacy(show_private)

    post |> Repo.paginate(request_params)
  end

  @doc """
  Get post summaries by a list of post id's.
  """
  def by_ids(ids) do
    post_summary_by_ids(ids, [])
  end

  def by_ids([], acc) do
    acc
  end

  def by_ids([id | tail], acc) do
    post_summary_by_ids(tail, [query_post_summary_by_id(id)|acc])
  end

  @doc """
  Return enough post data to summarize posts, queried by specific room
  """
  def by_room(limit, order_by, room_id, request_params) do
    summary(limit, order_by, room_id, request_params, true)
  end

  defp add_order_by_to_query(post_query, order_by) do
  	case order_by do
      :alltime ->
        post_query
          |> Ecto.Query.order_by([p], desc: p.votealltime)
      :vote ->
        post_query
          |> Ecto.Query.order_by([p], desc: p.voteprivate)
      :new ->
        post_query
          |> Ecto.Query.order_by(desc: :inserted_at)
      _ ->
        post_query
          |> Ecto.Query.order_by([p], desc: p.voteprivate)
    end
  end

  defp add_room_id_to_query(post_query, room_id) do
  	case room_id do
      :nil ->
        post_query
      _ ->
        post_query
          |> Ecto.Query.where(parentid: ^room_id) 
    end
  end

  defp query_check_for_privacy(post_query, show_private) do
  	cond do
      !show_private ->
        post_query
          |> Ecto.Query.where([p, u, pm, r], r.type != "private")
      true ->
        post_query
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

        post_with_body_sample = %{post_with_url | :body => String.slice(HtmlSanitizeEx.strip_tags(post.body), 0..@summary_body_preview_length)}

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
end