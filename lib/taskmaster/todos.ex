defmodule Taskmaster.Todos do
  alias Taskmaster.Todos.Todo
  alias Taskmaster.Repo
  import Ecto.Query

  @default_page_size 20
  @max_page_size 100

  def create_todo(user, attrs) do
    %Todo{}
    |> Todo.create_todo_changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user.id)
    |> Repo.insert()
  end

  def update_todo(todo, attrs) do
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

  @doc """
  Lists todos for a user with optional filtering, sorting, and pagination.

  ## Options
    * `:completed` - filter by completed status (boolean)
    * `:search` - case-insensitive search in title and description
    * `:sort_by` - field to sort by: "title", "completed", "inserted_at" (default: "inserted_at")
    * `:order` - sort direction: "asc" or "desc" (default: "desc")
    * `:page` - page number, 1-indexed (default: 1)
    * `:page_size` - items per page, max 100 (default: 20)
  """
  def list_todos(user_id, opts \\ %{}) do
    page = parse_page(opts["page"])
    page_size = parse_page_size(opts["page_size"])
    offset = (page - 1) * page_size

    base_query = from(t in Todo, where: t.user_id == ^user_id)

    query =
      base_query
      |> maybe_filter_completed(opts["completed"])
      |> maybe_filter_search(opts["search"])
      |> apply_sort(opts["sort_by"], opts["order"])

    total = Repo.aggregate(query, :count)
    todos = query |> limit(^page_size) |> offset(^offset) |> Repo.all()

    %{
      todos: todos,
      meta: %{
        page: page,
        page_size: page_size,
        total: total,
        total_pages: ceil_div(total, page_size)
      }
    }
  end

  def delete_todo(todo) do
    Repo.delete(todo)
  end

  # ── Private helpers ──

  defp maybe_filter_completed(query, nil), do: query
  defp maybe_filter_completed(query, "true"), do: where(query, [t], t.completed == true)
  defp maybe_filter_completed(query, "false"), do: where(query, [t], t.completed == false)
  defp maybe_filter_completed(query, _), do: query

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, search) do
    pattern = "%#{search}%"
    where(query, [t], ilike(t.title, ^pattern) or ilike(t.description, ^pattern))
  end

  defp apply_sort(query, sort_by, order) do
    sort_field = parse_sort_field(sort_by)
    sort_order = parse_sort_order(order)
    order_by(query, [t], [{^sort_order, ^sort_field}])
  end

  defp parse_sort_field("title"), do: :title
  defp parse_sort_field("completed"), do: :completed
  defp parse_sort_field("inserted_at"), do: :inserted_at
  defp parse_sort_field(_), do: :inserted_at

  defp parse_sort_order("asc"), do: :asc
  defp parse_sort_order("desc"), do: :desc
  defp parse_sort_order(_), do: :desc

  defp parse_page(nil), do: 1

  defp parse_page(val) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} when n > 0 -> n
      _ -> 1
    end
  end

  defp parse_page(val) when is_integer(val) and val > 0, do: val
  defp parse_page(_), do: 1

  defp parse_page_size(nil), do: @default_page_size

  defp parse_page_size(val) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} when n > 0 -> min(n, @max_page_size)
      _ -> @default_page_size
    end
  end

  defp parse_page_size(val) when is_integer(val) and val > 0, do: min(val, @max_page_size)
  defp parse_page_size(_), do: @default_page_size

  defp ceil_div(0, _), do: 1
  defp ceil_div(num, den), do: div(num + den - 1, den)
end
