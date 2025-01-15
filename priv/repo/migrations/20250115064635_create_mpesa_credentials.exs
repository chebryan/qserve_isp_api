defmodule QserveIspApi.Repo.Migrations.CreateMpesaCredentials do
  use Ecto.Migration

  def change do
    create table(:mpesa_credentials) do
      add :user_id, :integer, null: false
      add :consumer_key, :string, null: false
      add :consumer_secret, :string, null: false
      add :short_code, :string, null: false
      add :passkey, :string, null: false

      timestamps()
    end

    create unique_index(:mpesa_credentials, [:user_id])
  end
end
