defmodule QserveIspApi.Mpesa.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :user_id, :consumer_key, :consumer_secret, :short_code, :shortcode_type, :till_no, :head_office, :status, :apikey, :koposecret, :application, :passkey, :inserted_at, :updated_at]}
  schema "mpesa_credentials" do
    field :user_id, :integer
    field :consumer_key, :string
    field :consumer_secret, :string
    field :short_code, :string
    field :shortcode_type, :string # "Paybill", "Tillno", "Kopokopo"
    field :till_no, :string
    field :head_office, :string
    field :status, :boolean, default: false # Only one active per user
    field :apikey, :string
    field :koposecret, :string
    field :application, :string
    field :passkey, :string # New field added here

    timestamps()
  end

  @doc false
  def changeset(mpesa_credential, attrs) do
    mpesa_credential
    |> cast(attrs, [
      :user_id,
      :consumer_key,
      :consumer_secret,
      :short_code,
      :shortcode_type,
      :till_no,
      :head_office,
      :status,
      :apikey,
      :koposecret,
      :application,
      :passkey
    ])
    |> validate_required([:user_id, :short_code, :shortcode_type, :consumer_key, :consumer_secret])
    |> validate_length(:short_code, max: 8)
    # |> unique_constraint(:user_id, name: :mpesa_credentials_user_id_index)
    |> unique_constraint([:user_id, :shortcode_type], name: :mpesa_credentials_user_id_shortcode_type_index)

    # |> ensure_only_one_active(:status, :user_id)
  end



  # defp ensure_only_one_active(changeset, field, user_field) do
  #   if get_field(changeset, field) do
  #     user_id = get_field(changeset, user_field)

  #     query =
  #       from c in __MODULE__,
  #         where: c.user_id == ^user_id and c.status == true

  #     if Repo.exists?(query) do
  #       add_error(changeset, field, "Only one active shortcode is allowed per user.")
  #     else
  #       changeset
  #     end
  #   else
  #     changeset
  #   end
  # end
end
