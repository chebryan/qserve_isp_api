defmodule QserveIspApi.Payments.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payments" do
    field :user_id, :integer
    field :amount, :decimal
    field :phone_number, :string
    field :status, :string, default: "pending" # pending, completed, failed
    field :account_reference, :string
    field :transaction_description, :string
    field :package_id, :integer
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [
      :user_id,
      :amount,
      :phone_number,
      :status,
      :account_reference,
      :transaction_description,
      :package_id,
      :username
    ])
    |> validate_required([
      :user_id,
      :amount,
      :phone_number,
      :account_reference,
      :transaction_description,
      :package_id,
      :username
    ])
    |> validate_inclusion(:status, ["pending", "completed", "failed"])
  end
end
