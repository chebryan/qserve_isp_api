defmodule QserveIspApiWeb.MpesaController do
  use QserveIspApiWeb, :controller
  alias QserveIspApi.{Payments, Radius}
  alias QserveIspApi.Repo
  alias QserveIspApi.Payments.Payment
  alias QserveIspApi.MpesaTransactions.MpesaTransaction
  alias QserveIspApi.Mpesa
  alias QserveIspApi.Packages.Package
  alias QserveIspApiWeb.Utils.AuthUtils
  alias QserveIspApi.Mpesa.Credential


  @doc """
  Handle M-Pesa payment callback.
  """
  def handle_callback(conn, %{"Body" => %{"stkCallback" => callback_data}}) do
    Repo.transaction(fn ->
      checkout_request_id = callback_data["CheckoutRequestID"]
      result_code = callback_data["ResultCode"]
      result_desc = callback_data["ResultDesc"]

      # Fetch corresponding mpesa_transaction
      transaction =
        Repo.get_by!(MpesaTransaction, checkout_request_id: checkout_request_id)

      # Update mpesa_transactions table
      transaction =
        transaction
        |> MpesaTransaction.changeset(%{
          result_code: result_code,
          result_desc: result_desc,
          status: if(result_code == 0, do: "success", else: "failed"),
          raw_response: callback_data
        })
        |> Repo.update!()

      # Fetch related payment
      payment =
        Repo.get!(Payment, transaction.payment_id)

      if result_code == 0 do
        # Success: Extract metadata and update payments
        items = callback_data["CallbackMetadata"]["Item"]
        amount = extract_item(items, "Amount")
        phone_number = extract_item(items, "PhoneNumber")
        mpesa_receipt_number = extract_item(items, "MpesaReceiptNumber")
        transaction_date = extract_item(items, "TransactionDate") |> parse_transaction_date()

            # Fetch the package duration
        package = Repo.get!(Package, payment.package_id)


        # Update payment status
        payment
        |> Payment.changeset(%{status: "completed"})
        |> Repo.update!()

        # Perform RADIUS actions
        username = payment.username
        password = payment.username#generate_secret() # Generate a secure password for RADIUS
        session_timeout = package.duration # Example session timeout (24 hours)

        Radius.add_or_update_radcheck(username, password)
        Radius.add_radreply_details(username, session_timeout)
      else
        # Failure: Update payment status only
        payment
        |> Payment.changeset(%{status: "failed"})
        |> Repo.update!()
      end
    end)

    conn
    |> put_status(:ok)
    |> json(%{message: "Callback processed successfully"})
  end


  # def handle_callback(conn, %{"Body" => %{"stkCallback" => callback}}) do


  #   Repo.transaction(fn ->
  #     # Extract relevant details
  #     result_code = callback["ResultCode"]
  #     result_desc = callback["ResultDesc"]
  #     IO.inspect(callback, label: "=============CALLBACK RESPONSE===============")

  #     payment_id = extract_payment_id(callback)
  #     transaction_id = extract_transaction_id(callback)

  #     # Log the transaction in mpesa_transactions table
  #     Repo.insert!(%MpesaTransaction{
  #       payment_id: payment_id,
  #       transaction_id: transaction_id,
  #       status: if(result_code == 0, do: "success", else: "failed"),
  #       raw_response: callback
  #     })

  #     # Update payment status and RADIUS details
  #     case result_code do
  #       0 ->
  #         # Payment successful
  #         payment = Repo.get!(Payment, payment_id)
  #         Repo.update!(Ecto.Changeset.change(payment, %{status: "completed"}))

  #         # Add user to RADIUS tables
  #         username = payment.account_reference
  #         password = payment.account_reference#Payments.generate_secret()

  #         Radius.add_or_update_radcheck(username, password)
  #         Radius.add_radreply_details(username, 86400) # Session-Timeout in seconds

  #       _ ->
  #         # Payment failed
  #         payment = Repo.get!(Payment, payment_id)
  #         Repo.update!(Ecto.Changeset.change(payment, %{status: "failed"}))

  #         Phoenix.PubSub.broadcast(
  #           QserveIspApi.PubSub,
  #           "payment_status:#{payment_id}",
  #           {:payment_status_update, if(result_code == 0, do: :success, else: :failed)}
  #         )
  #     end
  #   end)

  #   send_resp(conn, :ok, "Callback processed successfully")
  # end

  # defp extract_payment_id(callback) do
  #   Enum.find_value(callback["CallbackMetadata"]["Item"], fn %{"Name" => name, "Value" => value} ->
  #     if name == "PaymentID", do: value, else: nil
  #   end)
  # end

  defp extract_item(items, name) do
    Enum.find_value(items, fn
      %{"Name" => ^name, "Value" => value} -> value
      _ -> nil
    end)
  end


  defp parse_transaction_date(nil), do: nil
  defp parse_transaction_date(date) do
    date
    |> Integer.to_string()
    |> Timex.parse!("{YYYY}{0M}{0D}{h24}{m}{s}")
  end


  defp generate_secret do
    :crypto.strong_rand_bytes(12)
    |> Base.url_encode64()
    |> binary_part(0, 12)
  end


  defp extract_payment_id(data) do
    Enum.find_value(data, fn
      %{"Name" => "PaymentID", "Value" => payment_id} -> payment_id
      _ -> nil
    end)
  end


  defp extract_transaction_id(callback) do
    Enum.find_value(callback["CallbackMetadata"]["Item"], fn %{"Name" => name, "Value" => value} ->
      if name == "MpesaReceiptNumber", do: value, else: nil
    end)
  end

  def add_credentials(conn, %{"credentials" => credentials_params}) do
    case AuthUtils.extract_user_id(conn) do
      {:ok, user_id} ->

        updated_params = Map.put(credentials_params, "user_id", user_id)

        case Mpesa.add_or_update_credentials(updated_params) do
          {:ok, _credential} ->
            conn
            |> put_status(:ok)
            |> json(%{message: "M-Pesa credentials saved successfully"})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: changeset_errors(changeset)})

          {:error, reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: reason})
        end


        {:error, reason} ->
          conn
          |> put_status(:unauthorized)
          |> json(%{error: reason})
      end
  end

  def add_shortcode(conn, %{"shortcode" => shortcode_params}) do
    case AuthUtils.extract_user_id(conn) do
      {:ok, user_id} ->
        # Add user_id to the parameters
        shortcode_params = Map.put(shortcode_params, "user_id", user_id)

        case Mpesa.add_or_update_credentials(shortcode_params) do
          {:ok, {:ok, %Credential{} = credential}} ->
            conn
            |> put_status(:created)
            |> json(%{
              message: "Shortcode added successfully",
              data: %{
                id: credential.id,
                user_id: credential.user_id,
                short_code: credential.short_code,
                shortcode_type: credential.shortcode_type,
                status: credential.status,
                inserted_at: credential.inserted_at,
                updated_at: credential.updated_at
              }
            })

          {:ok, {:error, %Ecto.Changeset{} = changeset}} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: format_changeset_errors(changeset)})

          {:error, reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: inspect(reason)})

          unexpected_response ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Unexpected response: #{inspect(unexpected_response)}"})
        end

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  def set_active_credential(conn, %{"id" => id, "user_id" => user_id}) do
    case Mpesa.set_active_credential(id, user_id) do
      {:ok, credential} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Active M-Pesa credential set successfully"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def list_user_credentials(conn, %{"user_id" => user_id}) do
    credentials = Mpesa.list_credentials_for_user(user_id)

    conn
    |> put_status(:ok)
    |> json(%{credentials: credentials})
  end


  # def add_shortcode(conn, %{"shortcode" => shortcode_params}) do
  #   if is_nil(shortcode_params["user_id"]) do
  #     conn
  #     |> put_status(:bad_request)
  #     |> json(%{error: "user_id is required"})
  #   else
  #     case Mpesa.add_or_update_credentials(shortcode_params) do
  #       {:ok, credential} ->
  #         conn
  #         |> put_status(:created)
  #         |> json(%{message: "Shortcode added successfully", credential: credential})

  #       {:error, %Ecto.Changeset{} = changeset} ->
  #         conn
  #         |> put_status(:unprocessable_entity)
  #         |> json(%{errors: changeset_errors(changeset)})

  #       {:error, reason} ->
  #         conn
  #         |> put_status(:internal_server_error)
  #         |> json(%{error: reason})
  #     end
  #   end
  # end

  # def add_shortcode(conn, %{"shortcode" => shortcode_params}) do
  #   case Mpesa.add_or_update_credentials(shortcode_params) do
  #     {:ok, credential} ->
  #       conn
  #       |> put_status(:created)
  #       |> json(%{message: "Shortcode added successfully", credential: credential})

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> json(%{errors: changeset_errors(changeset)})

  #     {:error, reason} ->
  #       conn
  #       |> put_status(:internal_server_error)
  #       |> json(%{error: reason})
  #   end
  # end

  # def add_shortcode(conn, %{"shortcode" => shortcode_params}) do
  #   case AuthUtils.extract_user_id(conn) do
  #     {:ok, user_id} ->
  #       # Add user_id to the params
  #       params_with_user = Map.put(shortcode_params, "user_id", user_id)

  #       case Mpesa.add_shortcode(params_with_user) do
  #         {:ok, shortcode} ->
  #           conn
  #           |> put_status(:created)
  #           |> json(%{message: "Shortcode added successfully", data: shortcode})

  #         {:error, changeset} ->
  #           conn
  #           |> put_status(:unprocessable_entity)
  #           |> json(%{errors: changeset})

  #         {:error, reason} ->
  #           conn
  #           |> put_status(:internal_server_error)
  #           |> json(%{error: reason})
  #       end

  #     {:error, _reason} ->
  #       conn
  #       |> put_status(:unauthorized)
  #       |> json(%{error: "Unauthorized"})
  #   end
  # end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Ecto.Changeset.apply_action(msg, opts)
    end)
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

end
