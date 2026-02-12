defmodule Taskmaster.Accounts do
    @moduledoc """
    The Accounts context — public API for user-related operations.
    This is the equivalent of user.service.ts in Express.
    """

    alias Taskmaster.Repo
    alias Taskmaster.Accounts.User

    @doc """
    Creates a new user.
    Express equivalent: createUser(dto) in user.service.ts
    """
    def create_user(attrs) do
      %User{}
      |> User.registration_changeset(attrs)
      |> Repo.insert()
    end

    @doc """
    Authenticates a user by email and password.
    Express equivalent: login(dto) in user.service.ts
    Returns {:ok, user} or {:error, :unauthorized}
    """
    def authenticate(email, password) do
      user = Repo.get_by(User, email: email)

      cond do
        user && Bcrypt.verify_pass(password, user.password_hash) ->
          {:ok, user}
        user ->
          {:error, :unauthorized}
        true ->
          # No user found — still run hash to prevent timing attacks
          Bcrypt.no_user_verify()
          {:error, :unauthorized}
      end
    end

    @doc """
    Gets a single user by ID.
    Express equivalent: getUserById(id) in user.service.ts
    """
    def get_user(id) do
      case Repo.get(User, id) do
        nil -> {:error, :not_found}
        user -> {:ok, user}
      end
    end

    @doc """
    Lists all users.
    Express equivalent: listUsers() in user.service.ts
    """
    def list_users do
      Repo.all(User)
    end
  end
