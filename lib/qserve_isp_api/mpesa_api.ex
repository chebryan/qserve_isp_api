defmodule QserveIspApi.MpesaApi do
  alias QserveIspApi.Repo
  alias QserveIspApi.Mpesa.Credential
  require Logger

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
    with {:ok, credentials} <- fetch_credentials(user_id),
         {:ok, token} <- generate_token(credentials) do
      timestamp = Timex.now() |> Timex.format!("{YYYY}{0M}{0D}{h24}{m}{s}")
      password =
        :crypto.hash(:sha256, "#{credentials.short_code}#{credentials.passkey}#{timestamp}")
        |> Base.encode64()

      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ]

      body = %{
        "BusinessShortCode" => credentials.short_code,
        "Password" => password,
        "Timestamp" => timestamp,
        "TransactionType" => "CustomerPayBillOnline",
        "Amount" => amount,
        "PartyA" => phone_number,
        "PartyB" => credentials.short_code,
        "PhoneNumber" => phone_number,
        "CallBackURL" => @mpesa_config[:callback_url],
        "AccountReference" => account_reference,
        "TransactionDesc" => transaction_description,
        "PaymentID" => payment_id
      }

      case HTTPoison.post(@mpesa_config[:stk_push_url], Jason.encode!(body), headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
          {:ok, Jason.decode!(response_body)}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end
  end
end
