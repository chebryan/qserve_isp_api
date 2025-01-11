defmodule QserveIspApi.Repo.Migrations.CreateOpenvpnTable do
  use Ecto.Migration

  def change do
    create table(:openvpn) do
      add :ip, :string, null: false
      add :crt, :text, null: false
      add :key, :text, null: false
      add :ca, :text, null: false

      timestamps()
    end

    create unique_index(:openvpn, [:ip])
  end
end
