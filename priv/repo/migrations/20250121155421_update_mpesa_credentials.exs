defmodule QserveIspApi.Repo.Migrations.UpdateMpesaCredentials do
  use Ecto.Migration

  def change do
    alter table(:mpesa_credentials) do
      add :shortcode_type, :string, null: false, default: "Paybill" # Paybill, Tillno, Kopokopo
      add :till_no, :string
      add :head_office, :string
      add :status, :boolean, default: false # Active flag, one per user
      add :apikey, :string
      add :koposecret, :string
      add :application, :string
    end
  end
end
