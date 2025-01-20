defmodule QserveIspApi.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:payments) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :package_id, references(:packages, on_delete: :delete_all), null: false
      add :username, :string, null: false
      add :amount, :decimal, null: false, scale: 2, precision: 10
      add :phone_number, :string, null: false
      add :status, :string, default: "pending", null: false
      add :account_reference, :string, null: false
      add :transaction_description, :string, null: false

      # Use current timestamps for inserted_at and updated_at
      # add :inserted_at, :utc_datetime, default: fragment("now()"), null: false
      # add :updated_at, :utc_datetime, default: fragment("now()"), null: false
      timestamps(type: :utc_datetime, default: fragment("now()"))
    end

    # Optional: Add indexes for faster lookups
    create index(:payments, [:user_id])
    create index(:payments, [:package_id])
    create index(:payments, [:username])



  end
end
