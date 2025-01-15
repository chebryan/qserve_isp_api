defmodule QserveIspApi.Repo.Migrations.RecreateMpesaTransactionsTable do
  use Ecto.Migration

  def change do
    # Drop the existing table if it exists
    drop table(:mpesa_transactions)

    # Recreate the mpesa_transactions table
    create table(:mpesa_transactions) do
      add :payment_id, :integer, null: false
      add :transaction_id, :string, null: false
      add :status, :string, default: "pending", null: false # pending, success, failed
      add :raw_response, :map, null: false

      timestamps()
    end

    # Add indexes for faster queries
    create index(:mpesa_transactions, [:payment_id])
    create index(:mpesa_transactions, [:transaction_id])
  end
end
