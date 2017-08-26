defmodule SmileysData.User do
  use SmileysData.Data, :model
  use Coherence.Schema

  schema "users" do
    field :name, :string
    field :email, :string
    field :reputation, :integer, default: 1
    field :drinks, :integer, default: 0
    field :moderating, {:array, :map}, default: []
    coherence_schema()

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email, :reputation, :drinks, :moderating] ++ coherence_fields())
    |> validate_required([:name])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:name)
    |> validate_length(:name, min: 2)
    |> validate_length(:name, max: 44)
    |> validate_format(:name, ~r/^[a-zA-Z0-9_]+$/)
    |> validate_coherence(params)
  end
end
