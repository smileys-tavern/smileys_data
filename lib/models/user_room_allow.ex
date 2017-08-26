defmodule SmileysData.UserRoomAllow do
  use SmileysData.Data, :model

  schema "userroomallows" do
    field :username, :string
    field :roomname, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:username, :roomname])
    |> validate_required([:username, :roomname])
    |> unique_constraint(:username_roomname)
    |> validate_length(:username, min: 2)
    |> validate_length(:username, max: 44)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/)
    |> validate_length(:roomname, min: 2)
    |> validate_length(:roomname, max: 44)
    |> validate_format(:roomname, ~r/^[a-zA-Z0-9_]+$/)
  end
end
