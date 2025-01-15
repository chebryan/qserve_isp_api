defmodule QserveIspApi.Repo.Migrations.CreateMpesaTransactions do
  use Ecto.Migration

  def change do
    create table(:mpesa_transactions) do
      add :user_id, :integer, null: false
      add :merchant_request_id, :string, null: false
      add :checkout_request_id, :string, null: false
      add :amount, :float
      add :mpesa_receipt_number, :string
      add :transaction_date, :naive_datetime
      add :phone_number, :string
      add :result_code, :integer
      add :result_desc, :string
      add :status, :string, null: false, default: "pending"

      timestamps()
    end
  end
end
