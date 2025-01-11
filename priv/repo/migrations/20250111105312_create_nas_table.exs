defmodule QserveIspApi.Repo.Migrations.CreateNasTable do
  use Ecto.Migration

  def change do
    create table(:nas) do
      add :nasname, :string, null: false
      add :shortname, :string
      add :type, :string
      add :ports, :integer
      add :secret, :string
      add :server, :string
      add :community, :string
      add :description, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:nas, [:user_id])
  end
end
