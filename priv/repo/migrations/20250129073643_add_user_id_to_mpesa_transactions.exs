defmodule QserveIspApi.Repo.Migrations.AddUserIdToMpesaTransactions do
  use Ecto.Migration

  def change do
    alter table(:mpesa_transactions) do
      add :user_id, :integer  # ✅ Step 1: Add column without NOT NULL constraint
    end

    flush()  # Ensures column is created before updates

    execute "UPDATE mpesa_transactions SET user_id = 1 WHERE user_id IS NULL"  # ✅ Step 2: Assign a default user

    alter table(:mpesa_transactions) do
      modify :user_id, :integer, null: false  # ✅ Step 3: Enforce NOT NULL constraint
    end
  end
end
