defmodule QserveIspApi.MpesaTransactions.MpesaTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [
    :id, :user_id, :payment_id, :checkout_request_id, :merchant_request_id,
    :amount, :mpesa_receipt_number, :transaction_date, :phone_number,
    :result_code, :result_desc, :status, :raw_response, :inserted_at, :updated_at
  ]}

  schema "mpesa_transactions" do
    field :user_id, :integer
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
    # |> cast(attrs, [
    #   :payment_id,
    #   :checkout_request_id,
    #   :merchant_request_id,
    #   :amount,
    #   :mpesa_receipt_number,
    #   :transaction_date,
    #   :phone_number,
    #   :result_code,
    #   :result_desc,
    #   :status,
    #   :raw_response,
    #   :user_id
    # ])
    |> cast(attrs, [:checkout_request_id, :phone_number, :amount, :payment_id, :status, :user_id])
    # |> validate_required([:checkout_request_id, :phone_number, :amount, :package_id, :status, :user_id])
    |> validate_required([:checkout_request_id])
    # |> unique_constraint(:checkout_request_id, name: "mpesa_transactions_checkout_request_id_index")  # ✅ Added constraint handling

  end
end
