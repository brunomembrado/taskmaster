defmodule TaskmasterWeb.AuthControllerTest do
  use TaskmasterWeb.ConnCase, async: true

  import Taskmaster.Fixtures

  setup %{conn: conn} do
    %{conn: put_req_header(conn, "content-type", "application/json")}
  end

  # ── REGISTER ──

  describe "POST /api/auth/register" do
    test "registers a new user", %{conn: conn} do
      conn =
        post(conn, "/api/auth/register", %{
          email: "new@test.com",
          username: "newuser",
          password: "Password123"
        })

      body = json_response(conn, 201)
      assert body["data"]["user"]["email"] == "new@test.com"
      assert body["data"]["user"]["username"] == "newuser"
      assert body["data"]["token"] != nil
    end

    test "fails with missing fields", %{conn: conn} do
      conn = post(conn, "/api/auth/register", %{email: "bad@test.com"})
      body = json_response(conn, 422)
      assert body["errors"]["username"] != nil
      assert body["errors"]["password"] != nil
    end

    test "fails with duplicate email", %{conn: conn} do
      user = user_fixture(%{"email" => "dup@test.com"})

      conn =
        post(conn, "/api/auth/register", %{
          email: user.email,
          username: "other",
          password: "Password123"
        })

      body = json_response(conn, 422)
      assert body["errors"]["email"] != nil
    end

    test "fails with short password", %{conn: conn} do
      conn =
        post(conn, "/api/auth/register", %{
          email: "short@test.com",
          username: "shortpw",
          password: "abc"
        })

      body = json_response(conn, 422)
      assert body["errors"]["password"] != nil
    end
  end

  # ── LOGIN ──

  describe "POST /api/auth/login" do
    test "logs in with valid credentials", %{conn: conn} do
      user_fixture(%{"email" => "login@test.com", "password" => "Password123"})

      conn =
        post(conn, "/api/auth/login", %{
          email: "login@test.com",
          password: "Password123"
        })

      body = json_response(conn, 200)
      assert body["data"]["user"]["email"] == "login@test.com"
      assert body["data"]["token"] != nil
    end

    test "fails with wrong password", %{conn: conn} do
      user_fixture(%{"email" => "wrong@test.com", "password" => "Password123"})

      conn =
        post(conn, "/api/auth/login", %{
          email: "wrong@test.com",
          password: "WrongPassword"
        })

      assert json_response(conn, 401)["error"] == "Invalid email or password"
    end

    test "fails with non-existent email", %{conn: conn} do
      conn =
        post(conn, "/api/auth/login", %{
          email: "nobody@test.com",
          password: "Password123"
        })

      assert json_response(conn, 401)["error"] == "Invalid email or password"
    end

    test "fails with missing params", %{conn: conn} do
      conn = post(conn, "/api/auth/login", %{})
      assert json_response(conn, 422)
    end
  end

  # ── ME ──

  describe "GET /api/auth/me" do
    test "returns current user with valid token", %{conn: conn} do
      user = user_fixture()
      token = auth_token(conn, user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/auth/me")

      body = json_response(conn, 200)
      assert body["data"]["user"]["id"] == user.id
      assert body["data"]["user"]["email"] == user.email
    end

    test "returns 401 without token", %{conn: conn} do
      conn = get(conn, "/api/auth/me")
      assert json_response(conn, 401)["error"] == "Missing or invalid token"
    end

    test "returns 401 with invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer garbage")
        |> get("/api/auth/me")

      assert json_response(conn, 401)["error"] == "Missing or invalid token"
    end
  end
end
