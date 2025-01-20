defmodule QserveIspApi.Repo.Migrations.CreatePackagesNasTable do
  use Ecto.Migration

  def change do
    create table(:packages_nas) do
      add :package_id, references(:packages, on_delete: :delete_all), null: false
      add :nas_id, references(:nas, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, default: fragment("now()"))
    end

    create unique_index(:packages_nas, [:package_id, :nas_id], name: :unique_package_nas)
  end
end
