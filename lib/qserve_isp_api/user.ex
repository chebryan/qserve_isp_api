defmodule QserveIspApi.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :email, :string
    field :phone, :string
    field :nas_limit, :integer
    has_many :nas, QserveIspApi.Nas

    timestamps(type: :utc_datetime)
  end

  @doc false

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :email, :phone, :nas_limit])
    |> validate_required([:username, :password, :email, :phone])
    |> validate_length(:password, min: 6)
    |> validate_format(:email, ~r/^[\w._%+-]+@[\w.-]+\.[a-zA-Z]{2,4}$/)
    |> validate_number(:nas_limit, greater_than_or_equal_to: 0)
    |> unique_constraint(:email)
    |> unique_constraint(:phone)
    |> unique_constraint(:username)
    |> put_password_hash()

  end

  # defp put_password_hash(changeset) do
  #   case get_change(changeset, :password) do
  #     nil -> changeset
  #     password -> put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))
  #   end
  # end
  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password -> put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    end
  end


end
