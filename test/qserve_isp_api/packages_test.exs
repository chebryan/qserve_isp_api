defmodule QserveIspApi.PackagesTest do
  use QserveIspApi.DataCase

  alias QserveIspApi.Packages

  describe "packages" do
    alias QserveIspApi.Packages.Package

    import QserveIspApi.PackagesFixtures

    @invalid_attrs %{name: nil, description: nil, duration: nil, price: nil, package_type: nil, user_id: nil}

    test "list_packages/0 returns all packages" do
      package = package_fixture()
      assert Packages.list_packages() == [package]
    end

    test "get_package!/1 returns the package with given id" do
      package = package_fixture()
      assert Packages.get_package!(package.id) == package
    end

    test "create_package/1 with valid data creates a package" do
      valid_attrs = %{name: "some name", description: "some description", duration: 42, price: "120.5", package_type: "some package_type", user_id: 42}

      assert {:ok, %Package{} = package} = Packages.create_package(valid_attrs)
      assert package.name == "some name"
      assert package.description == "some description"
      assert package.duration == 42
      assert package.price == Decimal.new("120.5")
      assert package.package_type == "some package_type"
      assert package.user_id == 42
    end

    test "create_package/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Packages.create_package(@invalid_attrs)
    end

    test "update_package/2 with valid data updates the package" do
      package = package_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", duration: 43, price: "456.7", package_type: "some updated package_type", user_id: 43}

      assert {:ok, %Package{} = package} = Packages.update_package(package, update_attrs)
      assert package.name == "some updated name"
      assert package.description == "some updated description"
      assert package.duration == 43
      assert package.price == Decimal.new("456.7")
      assert package.package_type == "some updated package_type"
      assert package.user_id == 43
    end

    test "update_package/2 with invalid data returns error changeset" do
      package = package_fixture()
      assert {:error, %Ecto.Changeset{}} = Packages.update_package(package, @invalid_attrs)
      assert package == Packages.get_package!(package.id)
    end

    test "delete_package/1 deletes the package" do
      package = package_fixture()
      assert {:ok, %Package{}} = Packages.delete_package(package)
      assert_raise Ecto.NoResultsError, fn -> Packages.get_package!(package.id) end
    end

    test "change_package/1 returns a package changeset" do
      package = package_fixture()
      assert %Ecto.Changeset{} = Packages.change_package(package)
    end
  end
end
