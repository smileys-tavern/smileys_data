defmodule SmileysData.RegisteredBotMeta do
  use SmileysData.Data, :model

  schema "registeredbotmetas" do
    field :botname, :string
    field :type, :string
    field :meta, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:botname, :type, :meta])
    |> validate_required([:botname, :type, :meta])
  end
end