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


  def get_last_package(mac_address) do
    query = """
    SELECT package_name, hours, acctstoptime as last_active
    FROM radacct
    WHERE callingstationid = $1
    ORDER BY acctstoptime DESC
    LIMIT 1;
    """
    case QserveIspApi.Repo.query(query, [mac_address]) do
      {:ok, %{rows: [[package_name, hours, last_active]]}} ->
        %{package_name: package_name, hours: hours, last_active: last_active}
      _ ->
        %{package_name: "Unknown", hours: 0, last_active: "N/A"}
    end
  end

  def get_user_session(mac_address) do
    query = """
    SELECT username, framedipaddress, acctstoptime as expiry_date
    FROM radacct
    WHERE callingstationid = $1
    ORDER BY acctstoptime DESC
    LIMIT 1;
    """
    case QserveIspApi.Repo.query(query, [mac_address]) do
      {:ok, %{rows: [[username, framed_ip, expiry_date]]}} ->
        %{username: username, mac_address: mac_address, ip_address: framed_ip, expiry_date: expiry_date}
      _ ->
        %{username: "Unknown", mac_address: mac_address, ip_address: "N/A", expiry_date: DateTime.utc_now()}
    end
  end

end
