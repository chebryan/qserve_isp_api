defmodule QserveIspApi.Repo.Migrations.CreateMpesaConfigs do
  use Ecto.Migration

  def change do
    create table(:mpesa_configs) do
      add :user_id, :integer, null: false
      add :base_url, :string, null: false
      add :consumer_key, :string, null: false
      add :consumer_secret, :string, null: false
      add :business_short_code, :string, null: false
      add :passkey, :string, null: false
      add :callback_url, :string, null: false

      timestamps()
    end

    create unique_index(:mpesa_configs, [:user_id])
  end
end
