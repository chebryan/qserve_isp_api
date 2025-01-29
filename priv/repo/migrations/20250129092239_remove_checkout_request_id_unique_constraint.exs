defmodule QserveIspApi.Repo.Migrations.RemoveCheckoutRequestIdUniqueConstraint do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE mpesa_transactions DROP CONSTRAINT IF EXISTS mpesa_transactions_checkout_request_id_index"
  end
end
