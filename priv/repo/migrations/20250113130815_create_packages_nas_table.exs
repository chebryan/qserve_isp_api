defmodule QserveIspApi.Repo.Migrations.CreatePackagesNasTable do
  use Ecto.Migration

  def change do
    create table(:packages_nas) do
      add :package_id, references(:packages, on_delete: :delete_all)
      add :nas_id, references(:nas, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:packages_nas, [:package_id, :nas_id], name: :unique_package_nas)
  end
end
