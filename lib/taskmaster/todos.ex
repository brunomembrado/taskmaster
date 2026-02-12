defmodule Taskmaster.Todos do
  alias Taskmaster.Todos.Todo
  alias Taskmaster.Repo
  import Ecto.Query

  def create_todo(user, attrs) do
    # For creating
    %Todo{}
    |> Todo.create_todo_changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user.id)
    |> Repo.insert()
  end

  def update_todo(todo, attrs) do
    # For updating
    todo
    |> Todo.update_todo_changeset(attrs)
    |> Repo.update()
  end

  def get_todo(id, user_id) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      todo -> {:ok, todo}
    end
  end

  def list_todos(user_id) do
    from(t in Todo, where: t.user_id == ^user_id)
    |> Repo.all()
  end

  def delete_todo(todo) do
    Repo.delete(todo)
  end
end
