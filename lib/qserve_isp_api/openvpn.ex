defmodule QserveIspApi.Openvpn do
  use Ecto.Schema
  import Ecto.Changeset

  schema "openvpn" do
    field :ip, :string
    field :crt, :string
    field :key, :string
    field :ca, :string

    timestamps()
  end

  @doc false
  def changeset(openvpn, attrs) do
    openvpn
    |> cast(attrs, [:ip, :crt, :key, :ca])
    |> validate_required([:ip, :crt, :key, :ca])
    |> unique_constraint(:ip)
  end
end
