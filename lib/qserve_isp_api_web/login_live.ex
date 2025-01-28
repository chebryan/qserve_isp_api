defmodule QserveIspApiWeb.LoginLive do
  use QserveIspApiWeb, :live_view

  alias QserveIspApi.Packages

  def mount(params, _session, socket) do
    packages = Packages.list_packages_for_nas_ip(params["nas_ipaddress"])
    mac = params["mac"]
    user_details = Packages.get_user_details(mac)

    if user_details[:active] do
      {:ok, push_redirect(socket, to: ~p"/dashboard/#{params["username"]}/#{params["nas_ipaddress"]}/#{mac}")}
    else
      {:ok, assign(socket, packages: packages, user_details: user_details)}
    end
  end

  def handle_event("select_package", %{"package" => package}, socket) do
    {:noreply, push_redirect(socket, to: ~p"/make_payment/#{socket.assigns.user_details.name}/#{socket.assigns.user_details.nas_ipaddress}/#{socket.assigns.user_details.mac}?package=#{package}")}
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
      <p>Welcome, <%= @user_details.name %></p>
      <ul>
        <%= for package <- @packages do %>
          <li>
            <button phx-click="select_package" phx-value-package={ package.id }>
              <%= package.name %> - <%= package.price %>
            </button>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
