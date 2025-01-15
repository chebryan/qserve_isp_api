defmodule QserveIspApi.MpesaConfig do
  use Ecto.Schema

  schema "mpesa_configs" do
    field :user_id, :integer
    field :base_url, :string
    field :consumer_key, :string
    field :consumer_secret, :string
    field :business_short_code, :string
    field :passkey, :string
    field :callback_url, :string

    timestamps()
  end
end
