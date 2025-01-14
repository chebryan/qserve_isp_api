defmodule QserveIspApiWeb.HotspotController do

    use QserveIspApiWeb, :controller
    alias QserveIspApiWeb.HotspotHTML


    alias QserveIspApi.Packages
    alias QserveIspApi.User
    alias QserveIspApi.Packages
    alias QserveIspApi.Repo
    alias QserveIspApi.Nas

    # def home(conn, _params) do
    #   # The home page is often custom made,
    #   # so skip the default app layout.
    #   render(conn, :home, layout: false)
    # end


    def home(conn, %{"username" => username, "nas_ipaddress" => nas_ip}) do
      # Fetch user details using the username
      user =
        Repo.get_by(User, username: username)
        |> case do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "User not found"})
            |> halt()

          user -> user
        end

        #uus
      # Fetch NAS and packages using nas_ipaddress
      packages =
        Repo.get_by(Nas, server: nas_ip)
        |> case do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "NAS not found"})
            |> halt()

          _nas ->
            Packages.list_packages_for_nas_ip(nas_ip)
        end

      # Set the view module and render the template
      # conn
      # |> put_view(HotspotHTML)
      # |> render("user_and_packages.html", user: user, packages: packages, nas_ip: nas_ip)
      render(conn, :home, user: user, packages: packages, nas_ip: nas_ip, active_package_id: nil )
      # render(conn, HotspotHTML, "user_and_packages.html", user: user, packages: packages, nas_ip: nas_ip)

    end

    @doc """
    Fetch and display packages based on the NAS IP.
    """
    def show_packages(conn, %{"nas_ip" => nas_ip} = params) do
      # Fetch packages associated with the NAS IP
      packages = Packages.list_packages_for_nas_ip(nas_ip)

      # Optional: Log the connecting user's MAC address
      mac = Map.get(params, "mac", "unknown")
      Logger.info("User with MAC #{mac} connected via NAS #{nas_ip}")

      # Render the packages for the hotspot login page
      render(conn, "packages.html", packages: packages)
    end

    def show_packages(conn, _params) do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Missing NAS IP"})
    end

  end
