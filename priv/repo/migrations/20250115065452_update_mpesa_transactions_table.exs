defmodule QserveIspApi.Repo.Migrations.UpdateMpesaTransactionsTable do
  use Ecto.Migration

  def change do
    alter table(:mpesa_transactions) do
      add :payment_id, :integer
      add :raw_response, :map
      modify :status, :string, default: "pending", null: false
    end
  end
end
