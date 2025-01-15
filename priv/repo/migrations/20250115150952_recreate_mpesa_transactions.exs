defmodule QserveIspApi.Repo.Migrations.RecreateMpesaTransactions do
  use Ecto.Migration

  def change do
    # Drop the table if it exists
    drop_if_exists table(:mpesa_transactions)

    # Create the new table
    create table(:mpesa_transactions) do
      add :payment_id, :integer
      add :checkout_request_id, :string, null: false
      add :merchant_request_id, :string
      add :amount, :decimal
      add :mpesa_receipt_number, :string
      add :transaction_date, :utc_datetime
      add :phone_number, :string
      add :result_code, :integer
      add :result_desc, :string
      add :status, :string, null: false
      add :raw_response, :map

      timestamps()
    end
  end
end
