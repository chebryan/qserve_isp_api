defmodule QserveIspApi.Repo.Migrations.CreateOpenvpnTable do
  use Ecto.Migration

  def change do
    create table(:openvpn) do
      add :ip, :string, null: false
      add :crt, :text, null: false
      add :key, :text, null: false
      add :ca, :text, null: false

      # Use current timestamp for inserted_at and updated_at
      # add :inserted_at, :utc_datetime, default: fragment("now()"), null: false
      # add :updated_at, :utc_datetime, default: fragment("now()"), null: false
      timestamps(type: :utc_datetime, default: fragment("now()"))
    end

    create unique_index(:openvpn, [:ip])


  end
end
