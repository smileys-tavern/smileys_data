defmodule SmileysData.Query.Sort.Posts do
  @doc """
  Lower private vote value for posts that fall within an upper and lower time bound by the given
  ratio.
  """
  def decay(ratio, interval1, interval2) do
    qry = "
      UPDATE posts SET voteprivate = (voteprivate - ROUND(voteprivate * " <> ratio <> "))
      WHERE (inserted_at - INTERVAL '8 hours', inserted_at - INTERVAL '8 hours') 
        OVERLAPS (CURRENT_TIMESTAMP - " <> interval1 <> ", CURRENT_TIMESTAMP - " <> interval2 <> ");
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