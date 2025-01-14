defmodule QserveIspApi.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add :name, :string, null: false
      add :duration, :integer, null: false
      add :price, :decimal, null: false, scale: 2, precision: 10
      add :description, :text
      add :package_type, :string, null: false  # Can be 'hotspot' or 'fixed'
      add :user_id, :integer, null: false

      timestamps()
    end
  end
end
