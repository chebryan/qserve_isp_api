defmodule QserveIspApi.PackagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `QserveIspApi.Packages` context.
  """

  @doc """
  Generate a package.
  """
  def package_fixture(attrs \\ %{}) do
    {:ok, package} =
      attrs
      |> Enum.into(%{
        description: "some description",
        duration: 42,
        name: "some name",
        package_type: "some package_type",
        price: "120.5",
        user_id: 42
      })
      |> QserveIspApi.Packages.create_package()

    package
  end
end
