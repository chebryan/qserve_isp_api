defmodule QserveIspApiWeb.LoginLive do
  use QserveIspApiWeb, :live_view

  alias QserveIspApi.Packages

  def mount(params, _session, socket) do
    packages = Packages.list_packages_for_nas_ip(params["nas_ipaddress"])
    mac = params["mac"]
    nas_ipaddress = params["nas_ipaddress"]
    user_details = Packages.get_user_details(mac)

    if user_details[:active] do
      {:ok, push_redirect(socket, to: ~p"/dashboard/#{params["username"]}/#{params["nas_ipaddress"]}/#{mac}")}
    else
      # {:ok, assign(socket, packages: packages, user_details: user_details)}
      {:ok,
      assign(socket,
        packages: packages,
        user_details: user_details,
        mac: mac,
        nas_ipaddress: nas_ipaddress
      )}
    end
  end

  def handle_event("select_package", %{"package" => package, "mac" => mac, "nas_ipaddress" => nas_ipaddress}, socket) do
    IO.inspect(mac, label: "==============MAC===============")
    IO.inspect(nas_ipaddress, label: "=========NAS====================")
    # with %{nas_ipaddress: nas_ipaddress, mac: mac} <- socket.assigns.user_details,
    #      true <- not is_nil(mac) and not is_nil(nas_ipaddress) do
      if not is_nil(mac) and not is_nil(nas_ipaddress) do
        # Redirect to the Make Payment page with validated parameters
        {:noreply,
         push_redirect(socket,
           to: ~p"/make_payment/#{mac}/#{nas_ipaddress}/#{mac}?package=#{package}"
         )}
      else
        {:noreply,
         put_flash(socket, :error, "Missing required details. Please try again.")}
      end
  end

  # def mount(params, _session, socket) do
  #   packages = Packages.list_packages_for_nas_ip(params["nas_ipaddress"])
  #   mac = params["mac"]
  #   user_details = Packages.get_user_details(mac)
  #   {:ok, assign(socket, packages: packages, user_details: user_details)}
  # end

  # def handle_event("select_package", %{"package" => package}, socket) do
  #   # Redirect to Make Payment page with package details
  #   {:noreply, push_redirect(socket, to: Routes.live_path(socket, QserveIspApiWeb.MakePaymentLive, package: package))}
  #   {:ok, push_redirect(socket, to: ~p"/dashboard/#{params["username"]}/#{params["nas_ipaddress"]}/#{mac}")}

  # end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Login</h1>
      <p>Welcome, <%= @user_details.username %></p>
      <ul>
        <%= for package <- @packages do %>
          <li>
            <button phx-click="select_package" phx-value-package={ package }  phx-value-mac={ @mac }   phx-value-nas_ipaddress={ @nas_ipaddress }>
              <%= package.name %> - <%= package.price %>
            </button>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
