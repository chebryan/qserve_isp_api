defmodule QserveIspApi.Radius do
  alias QserveIspApi.Repo
  alias QserveIspApi.Radius.Radcheck
  alias QserveIspApi.Radius.Radreply

  # Import Ecto.Query for using the `from/2` function
  import Ecto.Query

  @doc """
  Add or update a user's credentials in the `radcheck` table.
  """

  def add_user_to_radius(username, passwor) do

  end

  def add_or_update_radcheck(username, password) do
    query = from(rc in Radcheck, where: rc.username == ^username)

    case Repo.one(query) do
      nil ->
        # Insert new record
        %Radcheck{}
        |> Radcheck.changeset(%{
          username: username,
          attribute: "Cleartext-Password",
          op: ":=",
          value: password
        })
        |> Repo.insert()

      record ->
        # Update existing record
        record
        |> Radcheck.changeset(%{value: password})
        |> Repo.update()
    end
  end

    @doc """
  Add session details to the `radreply` table for a user.
  """
  def add_radreply_details(username, session_timeout) do
    Repo.insert!(%Radreply{
      username: username,
      attribute: "Session-Timeout",
      op: ":=",
      value: Integer.to_string(session_timeout)
    })
  end
end
