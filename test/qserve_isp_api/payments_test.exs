defmodule QserveIspApi.PaymentsTest do
  use QserveIspApi.DataCase

  alias QserveIspApi.Payments

  describe "payments" do
    alias QserveIspApi.Payments.Payment

    import QserveIspApi.PaymentsFixtures

    @invalid_attrs %{username: nil, package_id: nil, user_id: nil, amount_paid: nil, payment_status: nil, mpesa_code: nil}

    test "list_payments/0 returns all payments" do
      payment = payment_fixture()
      assert Payments.list_payments() == [payment]
    end

    test "get_payment!/1 returns the payment with given id" do
      payment = payment_fixture()
      assert Payments.get_payment!(payment.id) == payment
    end

    test "create_payment/1 with valid data creates a payment" do
      valid_attrs = %{username: "some username", package_id: 42, user_id: 42, amount_paid: "120.5", payment_status: "some payment_status", mpesa_code: "some mpesa_code"}

      assert {:ok, %Payment{} = payment} = Payments.create_payment(valid_attrs)
      assert payment.username == "some username"
      assert payment.package_id == 42
      assert payment.user_id == 42
      assert payment.amount_paid == Decimal.new("120.5")
      assert payment.payment_status == "some payment_status"
      assert payment.mpesa_code == "some mpesa_code"
    end

    test "create_payment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Payments.create_payment(@invalid_attrs)
    end

    test "update_payment/2 with valid data updates the payment" do
      payment = payment_fixture()
      update_attrs = %{username: "some updated username", package_id: 43, user_id: 43, amount_paid: "456.7", payment_status: "some updated payment_status", mpesa_code: "some updated mpesa_code"}

      assert {:ok, %Payment{} = payment} = Payments.update_payment(payment, update_attrs)
      assert payment.username == "some updated username"
      assert payment.package_id == 43
      assert payment.user_id == 43
      assert payment.amount_paid == Decimal.new("456.7")
      assert payment.payment_status == "some updated payment_status"
      assert payment.mpesa_code == "some updated mpesa_code"
    end

    test "update_payment/2 with invalid data returns error changeset" do
      payment = payment_fixture()
      assert {:error, %Ecto.Changeset{}} = Payments.update_payment(payment, @invalid_attrs)
      assert payment == Payments.get_payment!(payment.id)
    end

    test "delete_payment/1 deletes the payment" do
      payment = payment_fixture()
      assert {:ok, %Payment{}} = Payments.delete_payment(payment)
      assert_raise Ecto.NoResultsError, fn -> Payments.get_payment!(payment.id) end
    end

    test "change_payment/1 returns a payment changeset" do
      payment = payment_fixture()
      assert %Ecto.Changeset{} = Payments.change_payment(payment)
    end
  end
end
