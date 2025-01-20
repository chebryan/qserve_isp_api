defmodule QserveIspApi.Repo.Migrations.CreateMpesaTransactions do
  use Ecto.Migration

  def change do
    create table(:mpesa_transactions) do
      add :payment_id, references(:payments, on_delete: :delete_all), null: false
      add :checkout_request_id, :string, null: false
      add :merchant_request_id, :string
      add :amount, :decimal, scale: 2, precision: 10
      add :mpesa_receipt_number, :string
      add :transaction_date, :utc_datetime
      add :phone_number, :string
      add :result_code, :integer
      add :result_desc, :string
      add :status, :string, null: false
      add :raw_response, :map

      # Use current timestamps for inserted_at and updated_at
      # add :inserted_at, :utc_datetime, default: fragment("now()"), null: false
      # add :updated_at, :utc_datetime, default: fragment("now()"), null: false
      timestamps(type: :utc_datetime, default: fragment("now()"))
    end

    # Add indexes for faster lookups
    create index(:mpesa_transactions, [:payment_id])
    create unique_index(:mpesa_transactions, [:checkout_request_id])
    create index(:mpesa_transactions, [:mpesa_receipt_number])


  end
end
