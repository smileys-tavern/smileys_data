defmodule SmileysData.RegisteredBot do
  use SmileysData.Data, :model

  schema "registeredbots" do
    field :name, :string
    field :username, :string
    field :type, :string
    field :callback_module, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :username, :type, :callback_module])
    |> validate_required([:name, :type])
  end
end