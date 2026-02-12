defmodule TaskmasterWeb.TodoController do
  use TaskmasterWeb, :controller
  alias Taskmaster.Todos

  def create(conn, params) do
    current_user = conn.assigns.current_user

    case(Todos.create_todo(current_user, params)) do
      {:ok, todo} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            todo: format_todo(todo)
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    case(Todos.get_todo(id, current_user.id)) do
      {:ok, todo} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            todo: format_todo(todo)
          }
        })

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "not found"})
    end
  end

  def index(conn, _params) do
    user = conn.assigns.current_user
    todos = Todos.list_todos(user.id)

    conn |> put_status(:ok) |> json(%{data: %{todos: Enum.map(todos, &format_todo/1)}})
  end

  def update(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user

    with {:ok, todo} <- Todos.get_todo(id, user.id),
         {:ok, updated} <- Todos.update_todo(todo, params) do
      # both succeeded
      conn |> put_status(:ok) |> json(%{data: %{todo: format_todo(updated)}})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{errors: :not_found})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, todo} <- Todos.get_todo(id, user.id),
         {:ok, _} <- Todos.delete_todo(todo) do
      conn
      |> put_status(:ok)
      |> json(%{message: "todo deleted"})
    else
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "not found"})

      {:error, _changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "could not delete"})
    end
  end

  defp format_todo(todo) do
    %{
      id: todo.id,
      title: todo.title,
      description: todo.description,
      completed: todo.completed,
      user_id: todo.user_id
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
