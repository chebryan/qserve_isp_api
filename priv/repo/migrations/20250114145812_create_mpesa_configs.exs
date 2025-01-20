defmodule QserveIspApi.Repo.Migrations.CreateMpesaConfigs do
  use Ecto.Migration

  def change do
    create table(:mpesa_configs) do
      add :user_id, :integer, null: false
      add :base_url, :text, null: false
      add :consumer_key, :text, null: false
      add :consumer_secret, :text, null: false
      add :business_short_code, :text, null: false
      add :passkey, :text, null: false
      add :callback_url, :text, null: false
      timestamps(type: :utc_datetime, default: fragment("now()"))
    end

    create unique_index(:mpesa_configs, [:user_id])

    # Add a trigger to automatically update `updated_at` on row update

  end

end
