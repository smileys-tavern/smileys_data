defmodule SmileysData.UserSubscription do
  use SmileysData.Data, :model

  schema "usersubscriptions" do
    field :userid, :integer
    field :roomname, :string
    field :type, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:userid, :roomname, :type])
    |> validate_required([:userid, :roomname, :type])
  end
end
