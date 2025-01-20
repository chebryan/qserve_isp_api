defmodule QserveIsp.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
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

    create unique_index(:accounts, [:username])
    create unique_index(:accounts, [:email])
    create unique_index(:accounts, [:phone])


  end
end
