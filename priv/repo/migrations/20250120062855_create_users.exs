defmodule QserveIspApi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false
      add :password_hash, :string, null: false
      add :email, :string, null: false
      add :phone, :string, null: false
      add :nas_limit, :integer, default: 0, null: false

      # Default inserted_at and updated_at to current timestamp
      # add :inserted_at, :utc_datetime, default: fragment("now()"), null: false
      # add :updated_at, :utc_datetime, default: fragment("now()"), null: false
      timestamps(type: :utc_datetime, default: fragment("now()"))
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])
    create unique_index(:users, [:phone])

  end
end
