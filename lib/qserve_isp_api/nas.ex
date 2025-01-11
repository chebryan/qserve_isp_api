defmodule QserveIspApi.Nas do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [
    :id, :nasname, :shortname, :type, :ports, :secret, :server, :community,
    :description, :user_id, :inserted_at, :updated_at
  ]}
  schema "nas" do
    field :nasname, :string
    field :shortname, :string
    field :type, :string
    field :ports, :integer
    field :secret, :string
    field :server, :string
    field :community, :string
    field :description, :string

    belongs_to :user, QserveIspApi.User

    timestamps()
  end

  @doc false
  def changeset(nas, attrs) do
    nas
    |> cast(attrs, [
      :nasname,
      :shortname,
      :type,
      :ports,
      :secret,
      :server,
      :community,
      :description,
      :user_id
    ])
    |> validate_required([:nasname, :user_id])
    |> assoc_constraint(:user)
  end
end
