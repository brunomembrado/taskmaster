defmodule TaskmasterWeb.AuthController do
  use TaskmasterWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Taskmaster.Accounts
  alias TaskmasterWeb.Schemas

  tags(["Auth"])

  operation(:register,
    summary: "Register a new user",
    request_body: {"Registration params", "application/json", Schemas.RegisterRequest},
    responses: [
      created: {"User created", "application/json", Schemas.AuthResponse},
      unprocessable_entity: {"Validation errors", "application/json", Schemas.ValidationErrorResponse}
    ]
  )

  def register(conn, params) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        token = Phoenix.Token.sign(conn, "user_auth", user.id)

        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            user: format_user(user),
            token: token
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  operation(:login,
    summary: "Log in with email and password",
    request_body: {"Login credentials", "application/json", Schemas.LoginRequest},
    responses: [
      ok: {"Login successful", "application/json", Schemas.AuthResponse},
      unauthorized: {"Invalid credentials", "application/json", Schemas.ErrorResponse},
      unprocessable_entity: {"Missing params", "application/json", Schemas.ErrorResponse}
    ]
  )

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} ->
        token = Phoenix.Token.sign(conn, "user_auth", user.id)

        conn
        |> json(%{
          data: %{
            user: format_user(user),
            token: token
          }
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  # Catch-all for login with missing params
  def login(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: ["email and password are required"]})
  end

  operation(:me,
    summary: "Get current user profile",
    security: [%{"bearerAuth" => []}],
    responses: [
      ok: {"Current user", "application/json", Schemas.UserResponse},
      unauthorized: {"Missing or invalid token", "application/json", Schemas.ErrorResponse}
    ]
  )

  def me(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> put_status(:ok)
    |> json(%{
      data: %{user: format_user(user)}
    })
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp format_user(user) do
    %{
      id: user.id,
      email: user.email,
      username: user.username,
      full_name: user.full_name,
      role: user.role,
      active: user.active
    }
  end
end
