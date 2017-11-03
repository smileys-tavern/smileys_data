defmodule SmileysData.AnonymousPost do
  use SmileysData.Data, :model

  schema "anonymousposts" do
    field :hash, :string
    field :postid, :integer
    
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:hash, :postid])
    |> validate_required([:hash, :postid])
  end
end