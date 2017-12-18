defmodule SmileysData.Query.Post.Helper do
  
  require Ecto.Query

  alias SmileysData.Repo

  @moduledoc """
  Contains the helper methods other post queries rely on
  """

  # TODO: need to centralize these settings for use elsewhere and easy configuration
  @max_reputation 50
  @strong_reputation 30
  @good_reputation 20

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
  	get_post_frequency_user_limit(user, seconds_since_last_post, post_limits)
  end

  defp get_post_frequency_user_limit(user_reputation, seconds_since_last_post, post_limits) do
  	post_limit_i = cond do
  		user_reputation >= @max_reputation ->
  			3
  		user_reputation >= @strong_reputation ->
  			2
  		user_reputation >= @good_reputation ->
  			1
  		true ->
  			0 
    end

    limit = String.to_integer(Enum.at(post_limits, post_limit_i))

    if (seconds_since_last_post > limit) do
    	false
    else
    	limit
    end
  end
end