defmodule SmileysData.Repo.Migrations.AnonymousPosts do
  use Ecto.Migration

  def change do
	create table(:anonymousposts) do
      add :hash, :string
      add :postid, :int

      timestamps()
    end
    create index(:anonymousposts, [:hash])
    create index(:anonymousposts, [:postid])
  end
end
