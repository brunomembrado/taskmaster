defmodule Taskmaster.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "todos" do
    field(:title, :string)
    field(:description, :string)
    field(:completed, :boolean, default: false)
    belongs_to(:user, Taskmaster.Accounts.User)

    timestamps()
  end

  @doc """
  Changeset for TODO CREATION
  Used when creating todo
  """
  def create_todo_changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :description, :completed])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 40)
    |> validate_length(:description, max: 100)
  end

  @doc """
  Changeset for TODO UPDATE
  Used when updating todo
  """
  def update_todo_changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :description, :completed])
    |> validate_length(:title, min: 1, max: 40)
    |> validate_length(:description, max: 100)
  end
end
