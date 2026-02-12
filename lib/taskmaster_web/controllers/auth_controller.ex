defmodule TaskmasterWeb.AuthController do
  use TaskmasterWeb, :controller

  alias Taskmaster.Accounts

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
