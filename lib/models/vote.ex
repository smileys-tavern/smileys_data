defmodule SmileysData.Vote do
  use SmileysData.Data, :model

  schema "votes" do
    field :username, :string
    field :postid, :integer
    field :vote, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:username, :postid, :vote])
    |> validate_required([:username, :postid, :vote])
    |> unique_constraint(:username_postid)
  end
end