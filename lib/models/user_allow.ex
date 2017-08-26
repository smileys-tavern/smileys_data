defmodule SmileysData.UserAllow do
  use SmileysData.Data, :model

  schema "userallows" do
    field :userid, :integer
    field :roomid, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:userid, :roomid])
    |> validate_required([:userid, :roomid])
  end
end
