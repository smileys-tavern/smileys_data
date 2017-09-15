defmodule SmileysData.Repo.Migrations.RegisteredBots do
  use Ecto.Migration

  def change do
    create table(:registeredbots) do
      add :name, :string
      add :username, :string
      add :type, :string
      add :callback_module, :string

      timestamps()
    end
    create unique_index(:registeredbots, [:name])
    create index(:registeredbots, [:type])
  end
end
