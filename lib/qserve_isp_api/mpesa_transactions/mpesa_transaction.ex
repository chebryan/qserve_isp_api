defmodule QserveIspApi.MpesaTransactions.MpesaTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mpesa_transactions" do
    field :payment_id, :integer
    field :transaction_id, :string
    field :status, :string, default: "pending" # pending, success, failed
    field :raw_response, :map

    timestamps()
  end

  @doc false
  def changeset(mpesa_transaction, attrs) do
    mpesa_transaction
    |> cast(attrs, [:payment_id, :transaction_id, :status, :raw_response])
    |> validate_required([:payment_id, :transaction_id, :status, :raw_response])
    |> validate_inclusion(:status, ["pending", "success", "failed"])
  end
end
