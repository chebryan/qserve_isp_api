defmodule QserveIspApi.Repo.Migrations.CreateMpesaCredentials do
  use Ecto.Migration

  def change do
    create table(:mpesa_credentials) do
      add :user_id, references(:users, on_delete: :delete_all), null: false  # Foreign key constraint
      add :consumer_key, :string, null: false
      add :consumer_secret, :string, null: false
      add :short_code, :string, null: false
      add :passkey, :string, null: false

      # Use current timestamps for inserted_at and updated_at
      # add :inserted_at, :utc_datetime, default: fragment("now()"), null: false
      # add :updated_at, :utc_datetime, default: fragment("now()"), null: false
      timestamps(type: :utc_datetime, default: fragment("now()"))
    end

    # Unique constraint to ensure one set of credentials per user
    create unique_index(:mpesa_credentials, [:user_id])


  end
end
