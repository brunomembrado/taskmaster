defmodule TaskmasterWeb.TodoControllerTest do
  use TaskmasterWeb.ConnCase, async: true

  import Taskmaster.Fixtures

  setup %{conn: conn} do
    user = user_fixture()
    token = auth_token(conn, user)

    authed_conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")

    %{conn: conn, authed_conn: authed_conn, user: user}
  end

  # ── Auth required ──

  describe "authentication" do
    test "returns 401 without token", %{conn: conn} do
      conn = get(conn, "/api/todos")
      assert json_response(conn, 401)["error"] == "Missing or invalid token"
    end

    test "returns 401 with invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid.token.here")
        |> get("/api/todos")

      assert json_response(conn, 401)["error"] == "Missing or invalid token"
    end
  end

  # ── CREATE ──

  describe "POST /api/todos" do
    test "creates a todo", %{authed_conn: conn} do
      conn = post(conn, "/api/todos", %{title: "Buy milk", description: "2% milk"})
      body = json_response(conn, 201)

      assert body["data"]["todo"]["title"] == "Buy milk"
      assert body["data"]["todo"]["description"] == "2% milk"
      assert body["data"]["todo"]["completed"] == false
    end

    test "fails without title", %{authed_conn: conn} do
      conn = post(conn, "/api/todos", %{})
      assert json_response(conn, 422)["errors"]["title"] != nil
    end
  end

  # ── INDEX ──

  describe "GET /api/todos" do
    test "lists user's todos", %{authed_conn: conn, user: user} do
      todo_fixture(user, %{"title" => "My todo"})

      conn = get(conn, "/api/todos")
      body = json_response(conn, 200)

      assert length(body["data"]["todos"]) == 1
      assert hd(body["data"]["todos"])["title"] == "My todo"
      assert body["meta"]["total"] == 1
    end

    test "does not return other user's todos", %{authed_conn: conn} do
      other = user_fixture()
      todo_fixture(other, %{"title" => "Not mine"})

      conn = get(conn, "/api/todos")
      body = json_response(conn, 200)
      assert body["data"]["todos"] == []
      assert body["meta"]["total"] == 0
    end

    test "filters by completed", %{authed_conn: conn, user: user} do
      todo_fixture(user, %{"title" => "Done", "completed" => true})
      todo_fixture(user, %{"title" => "Not done"})

      conn = get(conn, "/api/todos?completed=true")
      body = json_response(conn, 200)
      assert length(body["data"]["todos"]) == 1
      assert hd(body["data"]["todos"])["title"] == "Done"
    end

    test "searches by title", %{authed_conn: conn, user: user} do
      todo_fixture(user, %{"title" => "Buy groceries"})
      todo_fixture(user, %{"title" => "Clean house"})

      conn = get(conn, "/api/todos?search=grocer")
      body = json_response(conn, 200)
      assert length(body["data"]["todos"]) == 1
    end

    test "paginates", %{authed_conn: conn, user: user} do
      for i <- 1..5, do: todo_fixture(user, %{"title" => "T#{i}"})

      conn = get(conn, "/api/todos?page=1&page_size=2")
      body = json_response(conn, 200)

      assert length(body["data"]["todos"]) == 2
      assert body["meta"]["total"] == 5
      assert body["meta"]["total_pages"] == 3
    end

    test "sorts by title ascending", %{authed_conn: conn, user: user} do
      todo_fixture(user, %{"title" => "Zebra"})
      todo_fixture(user, %{"title" => "Apple"})

      conn = get(conn, "/api/todos?sort_by=title&order=asc")
      body = json_response(conn, 200)
      titles = Enum.map(body["data"]["todos"], & &1["title"])
      assert hd(titles) == "Apple"
    end
  end

  # ── SHOW ──

  describe "GET /api/todos/:id" do
    test "returns a specific todo", %{authed_conn: conn, user: user} do
      todo = todo_fixture(user)

      conn = get(conn, "/api/todos/#{todo.id}")
      body = json_response(conn, 200)
      assert body["data"]["todo"]["id"] == todo.id
    end

    test "returns 404 for another user's todo", %{authed_conn: conn} do
      other = user_fixture()
      todo = todo_fixture(other)

      conn = get(conn, "/api/todos/#{todo.id}")
      assert json_response(conn, 404)
    end

    test "returns 404 for non-existent todo", %{authed_conn: conn} do
      conn = get(conn, "/api/todos/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end
  end

  # ── UPDATE ──

  describe "PATCH /api/todos/:id" do
    test "updates a todo", %{authed_conn: conn, user: user} do
      todo = todo_fixture(user)

      conn = patch(conn, "/api/todos/#{todo.id}", %{title: "Updated", completed: true})
      body = json_response(conn, 200)
      assert body["data"]["todo"]["title"] == "Updated"
      assert body["data"]["todo"]["completed"] == true
    end

    test "returns 404 for another user's todo", %{authed_conn: conn} do
      other = user_fixture()
      todo = todo_fixture(other)

      conn = patch(conn, "/api/todos/#{todo.id}", %{title: "Hacked"})
      assert json_response(conn, 404)
    end

    test "returns 422 for invalid data", %{authed_conn: conn, user: user} do
      todo = todo_fixture(user)

      conn = patch(conn, "/api/todos/#{todo.id}", %{title: ""})
      assert json_response(conn, 422)["errors"]["title"] != nil
    end
  end

  # ── DELETE ──

  describe "DELETE /api/todos/:id" do
    test "deletes a todo", %{authed_conn: conn, user: user} do
      todo = todo_fixture(user)

      resp_conn = delete(conn, "/api/todos/#{todo.id}")
      assert json_response(resp_conn, 200)["message"] == "todo deleted"

      # Verify it's gone — recycle the conn to make a fresh request
      token = auth_token(conn, user)

      verify_conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/todos/#{todo.id}")

      assert json_response(verify_conn, 404)
    end

    test "returns 404 for another user's todo", %{authed_conn: conn} do
      other = user_fixture()
      todo = todo_fixture(other)

      conn = delete(conn, "/api/todos/#{todo.id}")
      assert json_response(conn, 404)
    end
  end
end
