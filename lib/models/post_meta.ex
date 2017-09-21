defmodule SmileysData.PostMeta do
  use SmileysData.Data, :model

  schema "postmetas" do
    field :userid, :integer
    field :postid, :integer
    field :link, :string
    field :image, :string
    field :thumb, :string
    field :tags, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:userid, :postid, :link, :image, :thumb, :tags])
    |> validate_required([:userid])
    |> validate_length(:tags, max: 255)
    |> validate_format(:tags, ~r/^[a-zA-Z0-9, ]+$/)
    |> validate_format(:link, ~r/((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/)
  end
end
