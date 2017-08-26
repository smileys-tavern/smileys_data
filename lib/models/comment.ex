defmodule SmileysData.Comment do
  use SmileysData.Data, :model

  schema "comments" do
    field :posterid, :integer
    field :title, :string
    field :body, :string
    field :superparentid, :integer
    field :parentid, :integer
    field :parenttype, :string
    field :age, :integer
    field :hash, :string
    field :votepublic, :integer
    field :voteprivate, :integer
    field :votealltime, :integer
    field :depth, :integer
    field :name, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:posterid, :title, :body, :superparentid, :parentid, :parenttype, :age, :hash, :votepublic, :voteprivate, :votealltime])
    |> validate_length(:body, max: 500)
  end
end
