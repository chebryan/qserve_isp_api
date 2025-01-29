defmodule QserveIspApi.Repo.Migrations.UpdateMpesaCredentialsUniqueConstraint do
  use Ecto.Migration

  def change do
    # Drop the existing unique index on user_id
    drop_if_exists index(:mpesa_credentials, [:user_id], name: :mpesa_credentials_user_id_index)

    # Add a composite unique index on user_id and shortcode_type
    # create unique_index(:mpesa_credentials, [:user_id, :shortcode_type], name: :mpesa_credentials_user_id_shortcode_type_index)
  end
end
