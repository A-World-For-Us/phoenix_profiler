defmodule Demo.Repo.Migrations.AddGuestsTable do
  use Ecto.Migration

  def change do
    create table(:guests) do
      add :name, :string
      add :firstname, :string

      add :conference_id, references(:conferences, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:guests, [:conference_id], concurrently: true)
  end
end
