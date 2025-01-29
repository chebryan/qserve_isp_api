defmodule QserveIspApi.Repo.Migrations.AddUserIdToMpesaTransactions do
  use Ecto.Migration

  def up do
    alter table(:mpesa_transactions) do
      add :user_id, :integer
    end

    execute "UPDATE mpesa_transactions SET user_id = 1 WHERE user_id IS NULL"  # ✅ Backfill with default value

    alter table(:mpesa_transactions) do
      modify :user_id, :integer, null: false  # ✅ Enforce NOT NULL constraint
    end
  end

  def down do
    alter table(:mpesa_transactions) do
      remove :user_id
    end
  end
end
