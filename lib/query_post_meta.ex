defmodule SmileysData.QueryPostMeta do

  require Ecto.Query


  alias SmileysData.{PostMeta, Repo}

  @doc """
  Retrieve posts meta data via post id
  """
  def postmeta_by_post_id(post_id) do
    PostMeta |> Repo.get_by(postid: post_id)
  end
end