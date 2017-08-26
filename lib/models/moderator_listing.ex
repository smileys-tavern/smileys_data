defmodule SmileysData.ModeratorListing do
  use SmileysData.Data, :model

  schema "moderatorlistings" do
    field :userid, :integer
    field :roomid, :integer
    field :type, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:userid, :roomid, :type])
    |> validate_required([:userid, :roomid, :type])
    |> unique_constraint(:userid_roomid)
  end
end
