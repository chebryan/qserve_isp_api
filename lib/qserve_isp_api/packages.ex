defmodule QserveIspApi.Packages do
  @moduledoc """
  The Packages context.
  """

  import Ecto.Query, warn: false
  alias QserveIspApi.Repo
  alias QserveIspApi.Nas.Nas
  alias QserveIspApi.Packages.Package


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
          select: %{
            username: r.username,
            active: is_nil(r.acctstoptime),
            nas_ipaddress: r.nasipaddress,
            mac: r.callingstationid
          }
      )
      || %{username: "Guest", active: false, nas_ipaddress: nil, mac: mac}
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
