defmodule QserveIspApiWeb.PaymentController do
  use QserveIspApiWeb, :controller
  alias QserveIspApi.Payments

  @doc """
  List all payments for a specific ISP user.
  """
  def index(conn, %{"user_id" => user_id}) do
    payments = Payments.list_payments(user_id)
    render(conn, "index.json", payments: payments)
  end

  @doc """
  Initiate a payment for a package.
  """
  # def create(conn, %{"username" => username, "package_id" => package_id, "user_id" => user_id}) do
  #   case Payments.initiate_payment(%{username: username, package_id: package_id, user_id: user_id}) do
  #     {:ok, payment} ->
  #       conn
  #       |> put_status(:created)
  #       |> render("payment.json", payment: payment)

  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(QserveIspApiWeb.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end

  def create(conn, %{"username" => username, "package_id" => package_id, "phone_number" => phone_number}) do
    case Payments.initiate_payment(%{username: username, package_id: package_id, phone_number: phone_number}) do
      {:ok, payment} ->
        json(conn, %{message: "Payment initiated", payment: payment})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: changeset})
    end
  end

  @doc """
  Handle M-Pesa payment callback.
  """
  def callback(conn, params) do
    Payments.handle_payment_callback(params)
    json(conn, %{message: "Payment processed"})
  end
end
