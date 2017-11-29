defmodule SmileysData.Query.Post.Thread do
	require Ecto.Query

	alias SmileysData.{Comment, Repo}

	@doc """
	Retrieve a thread of comments complete with the level the comment exists at in the chain. A complex performance and cache architecture 
	sensitive query so we avoid the ORM for full control
	"""
	def by_post_id(post_id, mode) do
	  query_modifier = case mode do
	    "new" ->
	      "p.id * -1"
	    _ ->
	      "p.voteprivate * -1"
	  end

	  limit = case mode do
	    "focus" ->
	      Integer.to_string(@thread_query_focus_max)
	    _ ->
	      Integer.to_string(@thread_query_max)
	  end

	  # Do not allow concatination of strings here from user input
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

	  Enum.map res.rows, fn(row) ->
	    struct(Comment, Enum.zip(cols, row))
	  end
	end
end