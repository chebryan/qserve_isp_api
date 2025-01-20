defmodule QserveIspApi.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add :name, :string, null: false
      add :duration, :integer, null: false
      add :price, :decimal, null: false, scale: 2, precision: 10
      add :description, :text
      add :package_type, :string, null: false  # Can be 'hotspot' or 'fixed'
      add :user_id, references(:users, on_delete: :delete_all), null: false  # Establish foreign key relationship

      # Use current timestamps for inserted_at and updated_at
      # add :inserted_at, :utc_datetime, default: fragment("now()"), null: false
      # add :updated_at, :utc_datetime, default: fragment("now()"), null: false
      timestamps(type: :utc_datetime, default: fragment("now()"))
    end

    create index(:packages, [:user_id])  # Index for faster lookups by user_id



  end
end
