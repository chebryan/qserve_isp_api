defmodule QserveIspApiWeb.MpesaController do
  use QserveIspApiWeb, :controller
  alias QserveIspApi.{Payments, Radius}
  alias QserveIspApi.Repo
  alias QserveIspApi.Payments.Payment
  alias QserveIspApi.MpesaTransactions.MpesaTransaction
  alias QserveIspApi.Mpesa

  @doc """
  Handle M-Pesa payment callback.
  """
  def handle_callback(conn, %{"Body" => %{"stkCallback" => callback}}) do
    Repo.transaction(fn ->
      # Extract relevant details
      result_code = callback["ResultCode"]
      result_desc = callback["ResultDesc"]
      payment_id = extract_payment_id(callback)
      transaction_id = extract_transaction_id(callback)

      # Log the transaction in mpesa_transactions table
      Repo.insert!(%MpesaTransaction{
        payment_id: payment_id,
        transaction_id: transaction_id,
        status: if(result_code == 0, do: "success", else: "failed"),
        raw_response: callback
      })

      # Update payment status and RADIUS details
      case result_code do
        0 ->
          # Payment successful
          payment = Repo.get!(Payment, payment_id)
          Repo.update!(Ecto.Changeset.change(payment, %{status: "completed"}))

          # Add user to RADIUS tables
          username = payment.account_reference
          password = payment.account_reference#Payments.generate_secret()

          Radius.add_or_update_radcheck(username, password)
          Radius.add_radreply_details(username, 86400) # Session-Timeout in seconds

        _ ->
          # Payment failed
          payment = Repo.get!(Payment, payment_id)
          Repo.update!(Ecto.Changeset.change(payment, %{status: "failed"}))

          Phoenix.PubSub.broadcast(
            QserveIspApi.PubSub,
            "payment_status:#{payment_id}",
            {:payment_status_update, if(result_code == 0, do: :success, else: :failed)}
          )
      end
    end)

    send_resp(conn, :ok, "Callback processed successfully")
  end

  defp extract_payment_id(callback) do
    Enum.find_value(callback["CallbackMetadata"]["Item"], fn %{"Name" => name, "Value" => value} ->
      if name == "PaymentID", do: value, else: nil
    end)
  end

  defp extract_transaction_id(callback) do
    Enum.find_value(callback["CallbackMetadata"]["Item"], fn %{"Name" => name, "Value" => value} ->
      if name == "MpesaReceiptNumber", do: value, else: nil
    end)
  end

  def add_credentials(conn, %{"credentials" => credentials_params}) do
    case Mpesa.add_or_update_credentials(credentials_params) do
      {:ok, _credential} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "M-Pesa credentials saved successfully"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset.errors})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end



end