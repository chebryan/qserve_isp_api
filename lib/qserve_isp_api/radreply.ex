defmodule QserveIspApi.Radreply do
    use Ecto.Schema
    import Ecto.Changeset

    schema "radreply" do
      field :username, :string
      field :attribute, :string
      field :value, :string

      timestamps()
    end

    def changeset(radreply, attrs) do
      radreply
      |> cast(attrs, [:username, :attribute, :value])
      |> validate_required([:username, :attribute, :value])
    end
  end
