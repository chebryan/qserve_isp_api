defmodule QserveIspApiWeb.PackageController do
    use QserveIspApiWeb, :controller
    alias QserveIspApi.Packages
    alias QserveIspApiWeb.Utils.AuthUtils

    def index(conn, _params) do
      case AuthUtils.extract_user_id(conn) do
        {:ok, user_id} ->
          packages = Packages.list_packages_for_user(user_id)

          conn
          |> put_status(:ok)
          |> json(%{
            status: "success",
            data: packages
          })

        {:error, reason} ->
          conn
          |> put_status(:unauthorized)
          |> json(%{status: "error", message: reason})
      end
    end

    def show(conn, %{"id" => id}) do
      case AuthUtils.extract_user_id(conn) do
        {:ok, user_id} ->
          case Packages.get_package_for_user(id, user_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> json(%{status: "error", message: "Package not found"})

            package ->
              conn
              |> put_status(:ok)
              |> json(%{status: "success", data: package})
          end

        {:error, reason} ->
          conn
          |> put_status(:unauthorized)
          |> json(%{status: "error", message: reason})
      end
    end

    @doc """
    Updates a specific package for the authenticated user.
    """
    def update(conn, %{"id" => id, "package" => package_params}) do
      case AuthUtils.extract_user_id(conn) do
        {:ok, user_id} ->
          case Packages.get_package_for_user(id, user_id) do
            nil ->
              conn
              |> put_status(:not_found)
              |> json(%{status: "error", message: "Package not found"})

            package ->
              case Packages.update_package(package, package_params) do
                {:ok, updated_package} ->
                  conn
                  |> put_status(:ok)
                  |> json(%{status: "success", message: "Package updated successfully", data: updated_package})

                {:error, changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> json(%{status: "error", message: "Validation error", errors: changeset.errors})
              end
          end

        {:error, reason} ->
          conn
          |> put_status(:unauthorized)
          |> json(%{status: "error", message: reason})
      end
    end

    def create(conn, %{"package" => package_params}) do
      case AuthUtils.extract_user_id(conn) do
        {:ok, user_id} ->
          # Add user_id to the package params
          case Packages.create_package(Map.put(package_params, "user_id", user_id)) do
            {:ok, package} ->
              conn
              |> put_status(:created)
              |> json(%{
                status: "success",
                message: "Package created successfully",
                data: package
              })

            {:error, "A package with the same duration and price already exists for this user."} ->
              conn
              |> put_status(:conflict) # 409 Conflict
              |> json(%{
                status: "error",
                message: "A package with the same duration and price already exists for this user."
              })

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{
                status: "error",
                message: "Validation error",
                errors: changeset.errors
              })
          end

        {:error, reason} ->
          conn
          |> put_status(:unauthorized)
          |> json(%{status: "error", message: reason})
      end
    end


    # def create(conn, %{"package" => package_params}) do
    #   case AuthUtils.extract_user_id(conn) do
    #     {:ok, user_id} ->
    #       case Packages.create_package(Map.put(package_params, "user_id", user_id)) do
    #         {:ok, package} ->
    #           conn
    #           |> put_status(:created)
    #           # |> render("show.json", package: package)
    #           # |> json(%{status: "success", message: "Record inserted into radcheck successfully."})
    #           |> json( %{status: "success",message: "Package created successfully", data: package})

    #         {:error, changeset} ->
    #           conn
    #           |> put_status(:unprocessable_entity)
    #           |> json(%{status: "error", errors: changeset.errors})
    #      end
    #         {:error, reason} ->
    #           conn
    #           |> put_status(:unauthorized)
    #           |> json(%{error: reason})
    #       end
    # end


    def delete(conn, %{"id" => id}) do
      package = Packages.get_package!(id)

      case Packages.delete_package(package) do
        {:ok, _} ->
          send_resp(conn, :no_content, "")

        {:error, _} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render("error.json", %{error: "Unable to delete package"})
      end
    end

    def associate_package_to_nas(conn, %{"package_id" => package_id, "nas_ids" => nas_ids}) do
      # Convert package_id to integer if it's a string
      package_id = if is_binary(package_id), do: String.to_integer(package_id), else: package_id

      # Convert nas_ids to list of integers if needed
      nas_ids =
        Enum.map(nas_ids, fn id ->
          if is_binary(id), do: String.to_integer(id), else: id
        end)

      case Packages.assign_package_to_nas(package_id, nas_ids) do
        {:ok, _package} ->
          conn
          |> put_status(:ok)
          |> json(%{status: "success", message: "Package associated with NAS devices successfully."})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{status: "error", errors: changeset.errors})
      end
    end


  end
