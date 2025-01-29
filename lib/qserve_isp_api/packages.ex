defmodule QserveIspApi.Packages do
  @moduledoc """
  The Packages context.
  """

  import Ecto.Query, warn: false
  alias QserveIspApi.Repo
  alias QserveIspApi.Nas.Nas
  alias QserveIspApi.Packages.Package
  alias QserveIspApi.Payments.Payment

  @doc """
  Returns the list of packages for a specific user.
  """
    # def get_user_details(mac) do
    #   Repo.one(
    #     from r in "radacct",
    #       where: r.callingstationid == ^mac,
    #       select: %{
    #         username: r.username,
    #         active: is_nil(r.acctstoptime),
    #         nas_ipaddress: r.nasipaddress,
    #         mac: r.callingstationid
    #       }
    #   )
    #   || %{name: "Guest", active: false, mac: mac}
    # end

    def get_user_details(mac) do
      Repo.one(
        from r in "radacct",
          where: r.callingstationid == ^mac,
          order_by: [desc: r.acctstarttime], # Get the latest session
          limit: 1, # Ensure only one result is returned
          select: %{
            # name: r.username, # Use :name for consistency
            username: r.username,
            active: is_nil(r.acctstoptime),
            nas_ipaddress: r.nasipaddress,
            mac: r.callingstationid,
            expiry_date: r.acctstoptime
          }
      )
      || %{name: "Guest", username: "Guest", active: false, nas_ipaddress: nil, mac: mac}
      # Repo.one(query) # Returns nil if no record is found, avoiding errors
    end
  # end

  # def get_user_details(mac) do
  #   Repo.one(
  #     from r in "radacct",
  #     join: p in Payment, on: p.account_reference == r.callingstationid,
  #     where: r.callingstationid == ^mac,
  #     order_by: [desc: p.inserted_at],
  #     limit: 1,
  #     select: %{
  #       username: r.username,
  #       active: is_nil(r.acctstoptime),
  #       nas_ipaddress: r.nasipaddress,
  #       mac: r.callingstationid,
  #       expiry_date: r.acctstoptime
  #       #expiry_date: p.inserted_at + fragment("INTERVAL '1 day' * ?", p.duration)
  #     }
  #   ) || %{}  # Ensure it never returns nil
  # end


  def get_user_package(mac) do
    Repo.one(
      from p in Payment,
      join: pkg in Package, on: p.package_id == pkg.id,
      where: p.account_reference == ^mac,
      order_by: [desc: p.inserted_at],
      limit: 1,
      select: %{id: pkg.id, name: pkg.name, duration: pkg.duration, price: pkg.price}
    ) || %{} # Return an empty map instead of nil
  end

  # def get_user_package(mac) do
  #   Repo.one(
  #     from p in Package,
  #     join: pay in Payment,
  #     on: pay.package_id == p.id,
  #     join: r in "radacct",
  #     on: r.callingstationid == pay.account_reference,  # Match MAC address
  #     where: pay.account_reference == ^mac,
  #     order_by: [desc: pay.inserted_at],  # Get the most recent payment
  #     limit: 1,  # Only get the last one
  #     select: p
  #   )
  # end


  def get_user_data_usage(mac) do
    query =
      from r in "radacct",
        where: r.callingstationid == ^mac,
        select: %{
          upload_mb: fragment("ROUND(COALESCE(SUM(?)/1024/1024, 0), 2)", r.acctinputoctets),
          download_mb: fragment("ROUND(COALESCE(SUM(?)/1024/1024, 0), 2)", r.acctoutputoctets)
        }

    Repo.one(query) || %{upload_mb: 0, download_mb: 0}
  end

  # def get_user_details(mac) do
  #   user = Repo.get_by("radacct", %{callingstationid: mac})
  #   if user do
  #     %{name: user.username, active: user.acctstoptime == nil, nas_ipaddress: user.nasipaddress, mac: mac}
  #   else
  #     %{name: "Guest", active: false, mac: mac}
  #   end
  # end

  def list_packages_for_user(user_id) do
    Repo.all(from p in Package, where: p.user_id == ^user_id)
  end
  @doc """
  Gets a single package by ID.
  """
def get_package_for_user(id, user_id) do
  Repo.get_by(Package, id: id, user_id: user_id)
end

def get_package_details(id) do
  Repo.get_by(Package, id: id)
end
  @doc """
  Creates a package.
  """
  # def create_package(attrs \\ %{}) do
  #   %Package{}
  #   |> Package.changeset(attrs)
  #   |> Repo.insert()
  # end
  def create_package(attrs \\ %{}) do
    # Extract relevant attributes for checking duplicates
    %{"duration" => duration, "price" => price, "user_id" => user_id} = attrs

    # Check if a package already exists with the same duration, price, and user
    case Repo.get_by(Package, duration: duration, price: price, user_id: user_id) do
      nil ->
        # If no duplicate is found, proceed with insertion
        %Package{}
        |> Package.changeset(attrs)
        |> Repo.insert()

      _ ->
        # Return an error if a duplicate exists
        {:error, "A package with the same duration and price already exists for this user."}
    end
  end

  @doc """
  Updates a package.
  """
def update_package(%Package{} = package, attrs) do
  package
  |> Package.changeset(attrs)
  |> Repo.update()
end


  @doc """
  Deletes a package.
  """
  def delete_package(%Package{} = package) do
    Repo.delete(package)
  end


  def assign_package_to_nas(package_id, nas_ids) do
    package = Repo.get!(Package, package_id)
    nas_devices =   Repo.all(from n in Nas, where: n.id in ^nas_ids, select: [:id, :nasname])
      # Repo.all(from n in Nas, where: n.id in ^nas_ids)

    package
    |> Repo.preload(:nas_devices)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:nas_devices, nas_devices)
    |> Repo.update()
  end


  def list_packages_for_nas_ip(nas_ip) do
    Repo.all(
      from p in Package,
        join: pn in "packages_nas", on: pn.package_id == p.id,
        join: n in Nas, on: pn.nas_id == n.id,
        where: n.nasname == ^nas_ip,
        select: p
    )
  end

end
