defmodule SmileysData.Post do
  use SmileysData.Data, :model

  schema "posts" do
    field :posterid, :integer
    field :title, :string
    field :body, :string
    field :superparentid, :integer
    field :parentid, :integer
    field :parenttype, :string
    field :age, :integer
    field :hash, :string
    field :votepublic, :integer, default: 1
    field :voteprivate, :integer, default: 1
    field :votealltime, :integer, default: 1
    field :ophash, :string, default: ""

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:posterid, :title, :body, :superparentid, :parentid, :parenttype, :age, :hash, :votepublic, :voteprivate, :votealltime, :ophash])
    |> validate_required([:title])
    |> validate_length(:title, min: 2)
    |> validate_length(:title, max: 350)
    |> validate_format(:title, ~r/^[a-zA-Z0-9 \-\–\.,\/'’‘%?!:\)\(#&;]+$/)
    |> validate_length(:body, max: 3800)
  end
end