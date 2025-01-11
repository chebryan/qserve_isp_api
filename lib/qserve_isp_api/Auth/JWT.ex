defmodule QserveIspApi.Auth.JWT do
  use Joken.Config

  @key Application.compile_env(:qserve_isp_api, __MODULE__)[:secret_key]

  @impl true
  def token_config do
    default_claims()
    |> add_claim("user_id", nil, &is_integer/1)
    |> add_claim("username", nil, &is_binary/1)
  end

  def generate_token(user) do
    claims = %{
      "user_id" => user.id,
      "username" => user.username
    }



    signer = Joken.Signer.create("HS256", @key)
    token = generate_and_sign!(claims, signer)
    {:ok, token, claims}

  end

  def verify_token(token) do
    signer = Joken.Signer.create("HS256", @key)
    verify_and_validate(token, signer)
  end
end
