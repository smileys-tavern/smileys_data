defmodule SmileysData.Query.Post.Comment do
  require Ecto.Query

  alias SmileysData.{Post, Room, Repo}
  alias SmileysData.Query.Post.Helper
  alias SmileysData.Query.Vote, as: QueryVote

  @edit_msg "(edit) ?"

  @doc """
  Edit a post owned by the user
  """
  def edit(hash, body, user) do
    op = Post |> Repo.get_by(hash: hash)

    if op.posterid != user.id do
      nil
    else
      changeset = Post.changeset(op, %{"body" => String.replace(@edit_msg, "?", body)})

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
  def create(replyToHash, opHash, body, depth, user) do
    op = Post |> Repo.get_by(hash: opHash)
    replyToPost = Post |> Repo.get_by(hash: replyToHash)
    room = Room |> Repo.get_by(id: op.superparentid)

    case Helper.is_post_frequency_limit(user) do
      false ->
        changeset = Post.changeset(%Post{}, %{
          "body" => body, 
          "title" => "reply", 
          "superparentid" => room.id,
          "parentid" => replyToPost.id, 
          "parenttype" => "comment",
          "posterid" => user.id,
          "age" => 0,
          "hash" => Helper.create_hash(user.id, room.name),
          "votepublic" => 0,
          "voteprivate" => user.reputation,
          "votealltime" => user.reputation,
          "ophash" => opHash
        })

        case Repo.insert(changeset) do
          {:ok, post} ->
            if (user.name != "amysteriousstranger") do
              # TODO: move this out, too much logic in data lib
              QueryVote.up(post, user)

              post = put_in post.votepublic, 1

              {:ok, %{:comment => Map.merge(post, %{:depth => (depth + 1), :name => user.name}), :room => room, :op => op, :reply_to => replyToPost}}
            else
              {:ok, %{:comment => Map.merge(post, %{:depth => (depth + 1), :name => user.name}), :room => room, :op => op, :reply_to => replyToPost}}
            end
          {:error, changeset} ->
            {:error, changeset}
        end
        
      limit ->
        {:post_frequency_violation, limit}
    end
  end

  @doc """
  Validate that the body of the post stays to the required characters
  """
  def validate_comment_body(body) do
    String.match?(body, ~r/^[a-zA-Z0-9 \s.,?!:;\-"'\[\])(}{#%=*\^\/_]+$/)
  end
end