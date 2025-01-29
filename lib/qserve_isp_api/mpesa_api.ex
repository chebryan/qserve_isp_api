defmodule QserveIspApi.MpesaApi do
  alias QserveIspApi.Repo
  alias QserveIspApi.Mpesa.Credential
  alias QserveIspApi.MpesaTransactions.MpesaTransaction
  alias QserveIspApi.Mpesa
  require Logger
  use Timex
  use GenServer

  @mpesa_config Application.compile_env(:qserve_isp_api, :mpesa)

  @doc """
  Fetch M-Pesa credentials for the given user ID.
  """
  def fetch_credentials(user_id) do
    case Repo.get_by(Credential, user_id: user_id) do
      nil -> {:error, "M-Pesa credentials not found for user_id: #{user_id}"}
      credentials -> {:ok, credentials}
    end
  end

  def normalize_phone_number_(phone_number) do
    case String.starts_with?(phone_number, "0") do
      true -> "254" <> String.slice(phone_number, 1..-1)
      false -> phone_number
    end
  end

  def normalize_phone_number(phone_number) do
    cond do
      String.starts_with?(phone_number, "0") ->
        "254" <> String.slice(phone_number, 1..-1)

      String.starts_with?(phone_number, "7") ->
        "254" <> phone_number

      String.starts_with?(phone_number, "1") ->
        "254" <> phone_number

      String.starts_with?(phone_number, "+") ->
        String.slice(phone_number, 1..-1)

      true ->
        phone_number
    end
  end

  @doc """
  Generate M-Pesa access token using the user's credentials.
  """
  def generate_token(%Credential{consumer_key: consumer_key, consumer_secret: consumer_secret}) do
    credentials = Base.encode64("#{consumer_key}:#{consumer_secret}")

    headers = [
      {"Authorization", "Basic #{credentials}"}
    ]

    case HTTPoison.get(@mpesa_config[:token_url], headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"access_token" => token}} -> {:ok, token}
          {:error, _reason} -> {:error, :invalid_response}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Send an STK push request to M-Pesa.
  """

  def send_stk_push(user_id, payment_id, amount, phone_number, account_reference, transaction_description) do
    # Fetch active credentials for the user
    credentials = Mpesa.get_active_shortcode(user_id)

    case credentials.shortcode_type do
      "Paybill" ->
        handle_paybill_stk_push(credentials, payment_id, amount, phone_number, account_reference, transaction_description)

      "Tillno" ->
        handle_tillno_stk_push(credentials, payment_id, amount, phone_number, account_reference, transaction_description)

      "Kopokopo" ->
        handle_kopokopo_payment(credentials, payment_id, amount, phone_number, account_reference, transaction_description)

      _ ->
        {:error, "Unsupported shortcode type"}
    end
  end


  defp handle_paybill_stk_push(credentials, payment_id, amount, phone_number, account_reference, transaction_description) do
    token = get_or_refresh_access_token(credentials)

    payload = %{
      "BusinessShortCode" => credentials.short_code,
      "Password" => generate_password(credentials.short_code, credentials.passkey),
      "Timestamp" => generate_timestamp(),
      "TransactionType" => "CustomerPayBillOnline",
      "Amount" => amount,
      "PartyA" => phone_number,
      "PartyB" => credentials.short_code,
      "PhoneNumber" => phone_number,
      "CallBackURL" => "https://api.qserve-isp.net/api/pay/callback",
      "AccountReference" => account_reference,
      "TransactionDesc" => transaction_description
    }
    send_request(credentials.stk_push_url, token, payload, payment_id)
  end


  defp handle_tillno_stk_push(credentials, payment_id, amount, phone_number, account_reference, transaction_description) do
    token = get_or_refresh_access_token(credentials)

    payload = %{
      "BusinessShortCode" => credentials.till_no,
      "Password" => generate_password(credentials.till_no, credentials.passkey),
      "Timestamp" => generate_timestamp(),
      "TransactionType" => "CustomerBuyGoodsOnline",
      "Amount" => amount,
      "PartyA" => phone_number,
      "PartyB" => credentials.short_code,
      "PhoneNumber" => phone_number,
      "CallBackURL" => "https://api.qserve-isp.net/api/pay/callback",
      "AccountReference" => account_reference,
      "TransactionDesc" => transaction_description
    }

    send_request(credentials.stk_push_url, token, payload, payment_id)
  end

  defp handle_kopokopo_payment(credentials, _payment_id, amount, phone_number, account_reference, transaction_description) do
    # Placeholder for Kopokopo integration
    # You can replace this with actual Kopokopo API logic
    {:error, "Kopokopo integration not implemented yet"}
  end

  defp send_request(url, token, payload, payment_id) do
    case HTTPoison.post(
           url,
           Jason.encode!(payload),
           [{"Authorization", "Bearer #{token}"}, {"Content-Type", "application/json"}]
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Jason.decode!(body)
        save_transaction(payment_id, response)
        {:ok, response}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp save_transaction(payment_id, response) do
    Repo.insert!(%MpesaTransaction{
      payment_id: payment_id,
      checkout_request_id: response["CheckoutRequestID"],
      merchant_request_id: response["MerchantRequestID"],
      status: "initiated",
      raw_response: response
    })
  end
  def check_payment_status(package) do
    payment_status = Repo.get_by("payment", %{package_id: package.id})
    if payment_status && payment_status.status == "completed" do
      :success
    else
      :pending
    end
  end

  defp generate_password(short_code, passkey) do
    timestamp = generate_timestamp()
    Base.encode64("#{short_code}#{passkey}#{timestamp}")
  end

  defp generate_timestamp do
    Timex.format!(Timex.now(), "{YYYY}{0M}{0D}{h24}{0m}{0s}")
  end

  # defp get_or_refresh_access_token(credentials) do
  #   # Implement token generation/refresh logic using `credentials.consumer_key` and `credentials.consumer_secret`
  # end

  # def send_stk_push(user_id, payment_id, amount, phone_number, account_reference, transaction_description) do
  #   normalized_phone_number = normalize_phone_number(phone_number)
  #   with {:ok, credentials} <- fetch_credentials(user_id),
  #        {:ok, token} <- generate_token(credentials) do
  #     timestamp = Timex.now() |> Timex.format!("{YYYY}{0M}{0D}{h24}{m}{s}")
  #     password = Base.encode64("#{credentials.short_code}#{credentials.passkey}#{timestamp}")
  #       # password =
  #       #   :crypto.hash(:sha256, "#{credentials.short_code}#{credentials.passkey}#{timestamp}")
  #       #   |> Base.encode64()


  #     headers = [
  #       {"Authorization", "Bearer #{token}"},
  #       {"Content-Type", "application/json"}
  #     ]

  #     body = %{
  #       "BusinessShortCode" => credentials.short_code,
  #       "Password" => password,
  #       "Timestamp" => timestamp,
  #       "TransactionType" => "CustomerPayBillOnline",
  #       "Amount" => amount,
  #       "PartyA" => normalized_phone_number,
  #       "PartyB" => credentials.short_code,
  #       "PhoneNumber" => normalized_phone_number,
  #       "CallBackURL" => @mpesa_config[:callback_url],
  #       "AccountReference" => account_reference,
  #       "TransactionDesc" => transaction_description,
  #       "PaymentID" => payment_id
  #     }

  #     case HTTPoison.post(@mpesa_config[:stk_push_url], Jason.encode!(body), headers) do
  #       {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
  #         {:ok, Jason.decode!(response_body)}

  #       {:error, %HTTPoison.Error{reason: reason}} ->
  #         {:error, reason}
  #     end
  #   end
  # end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end
    @doc """
  Gets an access token using the given credentials. If an existing valid token is available, it is reused;
  otherwise, a new token is fetched from the API.
  """
  def get_or_refresh_access_token(%{
      consumer_key: consumer_key,
      consumer_secret: consumer_secret
    } = credentials) do
    case GenServer.call(__MODULE__, :get_token) do
      {:ok, token} -> {:ok, token}
      _ -> fetch_and_store_token(credentials)
    end
  end

  defp fetch_and_store_token(%{
        consumer_key: consumer_key,
        consumer_secret: consumer_secret
      }) do
    credentials = Base.encode64("#{consumer_key}:#{consumer_secret}")

    headers = [
    {"Authorization", "Basic #{credentials}"},
    {"Content-Type", "application/json"}
    ]

    case HTTPoison.get(@mpesa_config[:token_url], headers) do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
      case Jason.decode(body) do
        {:ok, %{"access_token" => token, "expires_in" => expires_in}} ->
          expiry_time = System.system_time(:second) + String.to_integer("#{expires_in}")

          # Store token and expiry time
          GenServer.cast(__MODULE__, {:set_token, token, expiry_time})
          {:ok, token}

        {:error, _reason} ->
          {:error, :invalid_response}
      end

    {:error, reason} ->
      {:error, reason}
    end
    end

  # defp fetch_and_store_token(%{
  #       consumer_key: consumer_key,
  #       consumer_secret: consumer_secret
  #     }) do
  #   credentials = Base.encode64("#{consumer_key}:#{consumer_secret}")

  #   headers = [
  #   {"Authorization", "Basic #{credentials}"},
  #   {"Content-Type", "application/json"}
  #   ]

  #   case HTTPoison.get(@mpesa_config[:token_url], headers) do
  #   {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
  #     case Jason.decode(body) do
  #       {:ok, %{"access_token" => token, "expires_in" => expires_in}} ->
  #         # Store token and expiry time
  #         expiry_time = System.system_time(:second) + expires_in
  #         GenServer.cast(__MODULE__, {:set_token, token, expiry_time})
  #         {:ok, token}

  #       {:error, _reason} ->
  #         {:error, :invalid_response}
  #     end

  #   {:error, reason} ->
  #     {:error, reason}
  #   end
  #   end

  ## GenServer Callbacks

  def init(_state), do: {:ok, %{token: nil, expiry: 0}}

  def handle_call(:get_token, _from, %{token: token, expiry: expiry} = state) do
  if token && System.system_time(:second) < expiry do
  {:reply, {:ok, token}, state}
  else
  {:reply, :expired, %{state | token: nil, expiry: 0}}
  end
  end

  def handle_cast({:set_token, token, expiry}, _state) do
  {:noreply, %{token: token, expiry: expiry}}
  end

end
