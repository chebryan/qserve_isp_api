defmodule QserveIspApi.Repo.Migrations.UpdatePaymentsTable do
  use Ecto.Migration

  def change do
    alter table(:payments) do
      add :account_reference, :string
      add :transaction_description, :string
      modify :status, :string, default: "pending", null: false
    end
  end
end
