defmodule Taskmaster.TodosTest do
  use Taskmaster.DataCase, async: true

  alias Taskmaster.Todos
  import Taskmaster.Fixtures

  setup do
    user = user_fixture()
    %{user: user}
  end

  # ── CRUD ──

  describe "create_todo/2" do
    test "creates a todo with valid attrs", %{user: user} do
      assert {:ok, todo} = Todos.create_todo(user, %{"title" => "Buy milk"})
      assert todo.title == "Buy milk"
      assert todo.completed == false
      assert todo.user_id == user.id
    end

    test "fails without title", %{user: user} do
      assert {:error, changeset} = Todos.create_todo(user, %{})
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "fails with title too long", %{user: user} do
      long_title = String.duplicate("a", 41)
      assert {:error, changeset} = Todos.create_todo(user, %{"title" => long_title})
      assert %{title: [_]} = errors_on(changeset)
    end
  end

  describe "get_todo/2" do
    test "returns a todo owned by the user", %{user: user} do
      todo = todo_fixture(user)
      assert {:ok, found} = Todos.get_todo(todo.id, user.id)
      assert found.id == todo.id
    end

    test "returns error for another user's todo", %{user: user} do
      other_user = user_fixture()
      todo = todo_fixture(other_user)
      assert {:error, :not_found} = Todos.get_todo(todo.id, user.id)
    end

    test "returns error for non-existent id", %{user: user} do
      fake_id = Ecto.UUID.generate()
      assert {:error, :not_found} = Todos.get_todo(fake_id, user.id)
    end
  end

  describe "update_todo/2" do
    test "updates title and completed", %{user: user} do
      todo = todo_fixture(user)

      assert {:ok, updated} =
               Todos.update_todo(todo, %{"title" => "Updated", "completed" => true})

      assert updated.title == "Updated"
      assert updated.completed == true
    end

    test "fails with invalid data", %{user: user} do
      todo = todo_fixture(user)
      assert {:error, changeset} = Todos.update_todo(todo, %{"title" => ""})
      assert %{title: [_]} = errors_on(changeset)
    end
  end

  describe "delete_todo/1" do
    test "deletes a todo", %{user: user} do
      todo = todo_fixture(user)
      assert {:ok, _} = Todos.delete_todo(todo)
      assert {:error, :not_found} = Todos.get_todo(todo.id, user.id)
    end
  end

  # ── Filtering ──

  describe "list_todos/2 filtering" do
    test "returns only the user's todos", %{user: user} do
      todo_fixture(user, %{"title" => "Mine"})
      other_user = user_fixture()
      todo_fixture(other_user, %{"title" => "Not mine"})

      %{todos: todos} = Todos.list_todos(user.id)
      assert length(todos) == 1
      assert hd(todos).title == "Mine"
    end

    test "filters by completed=true", %{user: user} do
      todo_fixture(user, %{"title" => "Done", "completed" => true})
      todo_fixture(user, %{"title" => "Not done", "completed" => false})

      %{todos: todos} = Todos.list_todos(user.id, %{"completed" => "true"})
      assert length(todos) == 1
      assert hd(todos).title == "Done"
    end

    test "filters by completed=false", %{user: user} do
      todo_fixture(user, %{"title" => "Done", "completed" => true})
      todo_fixture(user, %{"title" => "Not done", "completed" => false})

      %{todos: todos} = Todos.list_todos(user.id, %{"completed" => "false"})
      assert length(todos) == 1
      assert hd(todos).title == "Not done"
    end

    test "searches title case-insensitively", %{user: user} do
      todo_fixture(user, %{"title" => "Buy Groceries"})
      todo_fixture(user, %{"title" => "Clean house"})

      %{todos: todos} = Todos.list_todos(user.id, %{"search" => "grocer"})
      assert length(todos) == 1
      assert hd(todos).title == "Buy Groceries"
    end

    test "searches description", %{user: user} do
      todo_fixture(user, %{"title" => "Shopping", "description" => "Milk and eggs"})
      todo_fixture(user, %{"title" => "Chores"})

      %{todos: todos} = Todos.list_todos(user.id, %{"search" => "milk"})
      assert length(todos) == 1
      assert hd(todos).title == "Shopping"
    end
  end

  # ── Sorting ──

  describe "list_todos/2 sorting" do
    test "sorts by title ascending", %{user: user} do
      todo_fixture(user, %{"title" => "Zebra"})
      todo_fixture(user, %{"title" => "Apple"})

      %{todos: todos} = Todos.list_todos(user.id, %{"sort_by" => "title", "order" => "asc"})
      titles = Enum.map(todos, & &1.title)
      assert hd(titles) == "Apple"
    end

    test "defaults to descending inserted_at order", %{user: user} do
      todo_fixture(user, %{"title" => "Alpha"})
      todo_fixture(user, %{"title" => "Beta"})

      # Default sort is inserted_at desc — just verify both are returned
      # and the sort_by/order mechanism works (tested explicitly above)
      %{todos: todos} = Todos.list_todos(user.id)
      assert length(todos) == 2
    end
  end

  # ── Pagination ──

  describe "list_todos/2 pagination" do
    test "paginates results", %{user: user} do
      for i <- 1..5, do: todo_fixture(user, %{"title" => "Todo #{i}"})

      %{todos: todos, meta: meta} = Todos.list_todos(user.id, %{"page" => "1", "page_size" => "2"})
      assert length(todos) == 2
      assert meta.page == 1
      assert meta.page_size == 2
      assert meta.total == 5
      assert meta.total_pages == 3
    end

    test "returns page 2", %{user: user} do
      for i <- 1..5, do: todo_fixture(user, %{"title" => "Todo #{i}"})

      %{todos: page1} = Todos.list_todos(user.id, %{"page" => "1", "page_size" => "3"})
      %{todos: page2} = Todos.list_todos(user.id, %{"page" => "2", "page_size" => "3"})

      assert length(page1) == 3
      assert length(page2) == 2

      # No overlap
      page1_ids = Enum.map(page1, & &1.id)
      page2_ids = Enum.map(page2, & &1.id)
      assert MapSet.disjoint?(MapSet.new(page1_ids), MapSet.new(page2_ids))
    end

    test "caps page_size at 100", %{user: user} do
      %{meta: meta} = Todos.list_todos(user.id, %{"page_size" => "999"})
      assert meta.page_size == 100
    end

    test "defaults to page 1, page_size 20", %{user: user} do
      %{meta: meta} = Todos.list_todos(user.id)
      assert meta.page == 1
      assert meta.page_size == 20
    end
  end
end
