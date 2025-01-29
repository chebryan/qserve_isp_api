defmodule QserveIspApi.Repo.Migrations.AddUserIdToMpesaTransactions do
  use Ecto.Migration

  def change do
    alter table(:mpesa_transactions) do
      add :user_id, :integer, null: false  # Ensures every transaction is linked to a user
    end

    create index(:mpesa_transactions, [:user_id])  # Improves query performance
  end
end
