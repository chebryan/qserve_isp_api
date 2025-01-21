defmodule QserveIspApi.Radius.Radcheck do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true} # Auto-incrementing primary key
  schema "radcheck" do
    field :username, :string
    field :attribute, :string
    field :op, :string, default: ":="
    field :value, :string

    timestamps(inserted_at: false, updated_at: false)
  end

  @doc false
  def changeset(radcheck, attrs) do
    radcheck
    |> cast(attrs, [:username, :attribute, :op, :value])
    |> validate_required([:username, :attribute, :op, :value])
  end
end
