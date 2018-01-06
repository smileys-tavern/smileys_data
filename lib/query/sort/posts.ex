defmodule SmileysData.Query.Sort.Posts do
  alias SmileysData.Repo

  @doc """
  Lower private vote value for posts that fall within an upper and lower time bound by the given
  ratio.
  """
  def decay(ratio, intervalEnd, intervalStart) do
    # Window Overlaps Method: Post Time - Post Time + 1 Hour overlaps the timeframe for decay
    qry = "
      UPDATE posts SET voteprivate = (voteprivate - ROUND(voteprivate * " <> ratio <> "))
      WHERE (inserted_at, inserted_at + INTERVAL '1 HOUR') OVERLAPS 
        (CURRENT_TIMESTAMP - " <> intervalEnd <> ", CURRENT_TIMESTAMP - " <> intervalStart <> ");
    "

    case Ecto.Adapters.SQL.query(Repo, qry, []) do
      {:ok, result} ->
        %{num_rows: rows} = result
        {:ok, rows}
      _ ->
        {:error, "Error running decay query"}
    end
  end
end