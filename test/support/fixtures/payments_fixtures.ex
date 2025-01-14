defmodule QserveIspApi.PaymentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `QserveIspApi.Payments` context.
  """

  @doc """
  Generate a payment.
  """
  def payment_fixture(attrs \\ %{}) do
    {:ok, payment} =
      attrs
      |> Enum.into(%{
        amount_paid: "120.5",
        mpesa_code: "some mpesa_code",
        package_id: 42,
        payment_status: "some payment_status",
        user_id: 42,
        username: "some username"
      })
      |> QserveIspApi.Payments.create_payment()

    payment
  end
end
