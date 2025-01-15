defmodule QserveIspApi.MpesaApi do
  alias QserveIspApi.Repo
  alias QserveIspApi.Mpesa.Credential
  require Logger
  use Timex


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

  def normalize_phone_number(phone_number) when is_binary(phone_number) do
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
    normalized_phone_number = normalize_phone_number(phone_number)
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
        "PartyA" => normalized_phone_number,
        "PartyB" => credentials.short_code,
        "PhoneNumber" => normalized_phone_number,
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
