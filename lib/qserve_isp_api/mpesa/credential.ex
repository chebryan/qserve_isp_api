defmodule QserveIspApi.Mpesa.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mpesa_credentials" do
    field :user_id, :integer
    field :consumer_key, :string
    field :consumer_secret, :string
    field :short_code, :string
    field :passkey, :string

    timestamps()
  end

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:user_id, :consumer_key, :consumer_secret, :short_code, :passkey])
    |> validate_required([:user_id, :consumer_key, :consumer_secret, :short_code, :passkey])
  end
end
