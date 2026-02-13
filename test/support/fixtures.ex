defmodule Taskmaster.Fixtures do
  @moduledoc """
  Test factory helpers — creates database records for tests.
  Express equivalent: a helper like createTestUser() in your test utils.
  """

  alias Taskmaster.{Accounts, Todos}

  def user_fixture(attrs \\ %{}) do
    unique = System.unique_integer([:positive])

    defaults = %{
      "email" => "user#{unique}@test.com",
      "username" => "user#{unique}",
      "password" => "Password123",
      "full_name" => "Test User #{unique}"
    }

    {:ok, user} =
      defaults
      |> Map.merge(attrs)
      |> Accounts.create_user()

    user
  end

  def todo_fixture(user, attrs \\ %{}) do
    unique = System.unique_integer([:positive])

    defaults = %{
      "title" => "Todo #{unique}",
      "description" => "Description #{unique}"
    }

    {:ok, todo} =
      defaults
      |> Map.merge(attrs)
      |> then(&Todos.create_todo(user, &1))

    todo
  end

  def auth_token(_conn, user) do
    Phoenix.Token.sign(TaskmasterWeb.Endpoint, "user_auth", user.id)
  end
end
