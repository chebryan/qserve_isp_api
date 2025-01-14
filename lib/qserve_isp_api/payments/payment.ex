defmodule QserveIspApi.Payments.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payments" do
    field :username, :string
    field :package_id, :integer
    field :user_id, :integer
    field :amount_paid, :decimal
    field :payment_status, :string
    field :mpesa_code, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:username, :package_id, :user_id, :amount_paid, :payment_status, :mpesa_code])
    |> validate_required([:username, :package_id, :user_id, :amount_paid, :payment_status])
    |> validate_number(:amount_paid, greater_than_or_equal_to: 0)
  end
end
