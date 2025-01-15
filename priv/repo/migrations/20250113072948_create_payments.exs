defmodule QserveIspApi.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:payments) do
      add :username, :string, null: false
      add :package_id, references(:packages, on_delete: :delete_all), null: false
      add :user_id, :integer, null: false
      add :amount, :decimal, null: false, scale: 2, precision: 10
      add :status, :string, null: false, default: "pending"
      add :mpesa_code, :string
      timestamps()
    end

    create index(:payments, [:package_id])
    create index(:payments, [:user_id])
  end
end
