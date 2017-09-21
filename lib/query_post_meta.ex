defmodule SmileysData.QueryPostMeta do

  require Ecto.Query


  alias SmileysData.{PostMeta, Repo}

  @doc """
  Retrieve posts meta data via post id
  """
  def postmeta_by_post_id(post_id) do
    PostMeta |> Repo.get_by(postid: post_id)
  end

  @doc """
  Retrieve a posts meta data via link url
  """
  def postmeta_by_link(link) do
  	case link do
  		nil ->
  			nil
  		_ ->
  			PostMeta |> Repo.get_by(link: link)
  	end
  end
end