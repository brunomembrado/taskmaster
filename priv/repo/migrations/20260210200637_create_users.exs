defmodule Taskmaster.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :username, :string, null: false, size: 100
      add :password_hash, :string, null: false
      add :full_name, :string
      add :role, :string, null: false, default: "member"
      add :active, :boolean, null: false, default: true

      # Creates inserted_at and updated_at columns
      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
  end
end
