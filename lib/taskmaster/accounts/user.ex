defmodule Taskmaster.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field(:email, :string)
    field(:username, :string)
    field(:password_hash, :string)
    field(:full_name, :string)

    field(:role, Ecto.Enum,
      values: [:admin, :member],
      default: :member
    )

    field(:active, :boolean, default: true)

    # Virtual field — exists in the struct but NOT in the database
    field(:password, :string, virtual: true)

    timestamps()
  end

  @doc """
  Changeset for REGISTRATION — requires email, username, password.
  Used when creating a new user from scratch.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password, :full_name])
    |> validate_required([:email, :username, :password])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
    |> validate_length(:username, min: 3, max: 100)
    |> validate_length(:password, min: 8)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> put_password_hash()
  end

  @doc """
  Changeset for PROFILE UPDATES — no password required.
  Used when updating name, username, etc.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :full_name, :active])
    |> validate_length(:username, min: 3, max: 100)
    |> unique_constraint(:username)
  end

  @doc """
  Changeset for PASSWORD CHANGE — requires current validation externally,
  then just hashes the new password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8)
    |> put_password_hash()
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
