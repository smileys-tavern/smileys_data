defmodule SmileysData.Repo.Migrations.RegisteredBotsMeta do
  use Ecto.Migration

  def change do
    create table(:registeredbotsmeta) do
      add :botname, :string
      add :type, :string
      add :meta, :string

      timestamps()
    end
    create index(:registeredbotsmeta, [:botname])
    create index(:registeredbotsmeta, [:type])
  end
end
