defmodule SmileysData.Query.Post.Anonymous do

  alias SmileysData.{AnonymousPost, Repo}

  @doc """
  Record the happening of an anonymous post
  """
  def add(postid, hash) do
    changeset = AnonymousPost.changeset(%AnonymousPost{}, %{"hash" => hash, "postid" => postid})

    Repo.insert(changeset)
  end

  @doc """
  Retrieve the last anonymous post record by user token
  """
  def last_by_user(hash) do
    AnonymousPost |> Repo.get_by(hash: hash)
  end
end