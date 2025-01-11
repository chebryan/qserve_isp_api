defmodule QserveIspApi.VPNUser do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields [:username, :value]
  @optional_fields [:attribute, :op]

  schema "radcheck" do
    field :username, :string
    field :attribute, :string, default: "Cleartext-Password" # Used for password validation
    field :op, :string, default: ":=" # Operator for comparison
    field :value, :string # The password or credential value

    timestamps() # Optional: Add if your `radcheck` table has `inserted_at` and `updated_at`
  end

  @doc false
  def changeset(vpn_user, attrs) do
    vpn_user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:username, min: 3, max: 50)
    |> validate_length(:value, min: 6, max: 128)
    # |> unique_constraint(:username, name: :radcheck_username_index) # Add this if `username` is unique
  end
end
