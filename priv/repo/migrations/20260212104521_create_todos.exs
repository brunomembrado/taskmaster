defmodule Taskmaster.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:title, :string, null: false)
      add(:description, :string, null: true)
      add(:completed, :boolean, default: false)
      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end
  end
end
