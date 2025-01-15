defmodule QserveIspApi.Repo.Migrations.RecreatePaymentsTable do
  use Ecto.Migration

  def change do
    # Drop the existing table
    drop table(:payments)

    # Recreate the payments table
    create table(:payments) do
      add :user_id, :integer, null: false
      add :package_id, references(:packages, on_delete: :delete_all), null: false
      add :username, :string, null: false
      add :amount, :decimal, null: false
      add :phone_number, :string, null: false
      add :status, :string, default: "pending", null: false
      add :account_reference, :string, null: false
      add :transaction_description, :string, null: false


      timestamps()
    end

    # Optional: Add indexes
    create index(:payments, [:user_id])
    create index(:payments, [:package_id])
    create index(:payments, [:username])
  end
end
