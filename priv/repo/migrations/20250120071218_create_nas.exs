defmodule QserveIspApi.Repo.Migrations.CreateNas do
  use Ecto.Migration

  def change do
    create table(:nas) do
      add :nasname, :string, null: false
      add :shortname, :string, null: false
      add :type, :string, default: "other", null: false
      add :ports, :integer
      add :secret, :string, null: false
      add :server, :string
      add :community, :string
      add :description, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, default: fragment("now()"))
    end

    # Add index for user_id for faster lookups
    create index(:nas, [:user_id])
  end
end
