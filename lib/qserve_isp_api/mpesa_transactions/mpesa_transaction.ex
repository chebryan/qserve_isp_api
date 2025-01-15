defmodule QserveIspApi.MpesaTransactions.MpesaTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mpesa_transactions" do
    field :payment_id, :integer
    field :checkout_request_id, :string
    field :merchant_request_id, :string
    field :amount, :decimal
    field :mpesa_receipt_number, :string
    field :transaction_date, :utc_datetime
    field :phone_number, :string
    field :result_code, :integer
    field :result_desc, :string
    field :status, :string
    field :raw_response, :map

    timestamps()
  end

  @doc false
  def changeset(mpesa_transaction, attrs) do
    mpesa_transaction
    |> cast(attrs, [
      :payment_id,
      :checkout_request_id,
      :merchant_request_id,
      :amount,
      :mpesa_receipt_number,
      :transaction_date,
      :phone_number,
      :result_code,
      :result_desc,
      :status,
      :raw_response
    ])
    |> validate_required([
      :checkout_request_id,
      :status
    ])
  end
end
