defmodule QserveIspApi.Packages.Package do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :description, :duration, :price, :package_type, :inserted_at, :updated_at]}
  schema "packages" do
    field :name, :string
    field :description, :string
    field :duration, :integer
    field :price, :decimal
    field :package_type, :string
    field :user_id, :integer


    many_to_many :nas_devices, QserveIspApi.Nas, join_through: "packages_nas"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [:name, :duration, :price, :description, :package_type, :user_id])
    |> validate_required([:name, :duration, :price, :description, :package_type, :user_id])
  end
end
