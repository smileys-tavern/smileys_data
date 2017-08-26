defmodule SmileysData do
  @moduledoc """
  Module mainly handling data querying for a Smileys style web site.
  """

  @doc """
  Execute a query string and return a generalized list of mapped results.

  ## Examples

      iex> SmileysData.QueryMapper("SELECT SomeCol1, SomeCol2 FROM SomeTable LIMIT $1;", [2])
      [%{:SomeCol1 => someVal, :SomeCol2 => someVal}, %{:SomeCol1 => someVal, :SomeCol2 => someVal}]

  """
  def raw_query(query_string) do
    raw_query(query_string, [])
  end

  def raw_query(query_string, query_vars) do
    Ecto.Adapters.SQL.query!(SmileysData.Repo, query_string, query_vars)
  end
end