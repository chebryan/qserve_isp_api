defmodule QserveIspApiWeb.ExpiryLive do
  use QserveIspApiWeb, :live_view

  alias QserveIspApi.Radius

  def mount(_params, session, socket) do
    user_mac = session["mac_address"]
    user_ip = session["ip_address"]
    user_data = Radius.get_user_session(user_mac)
    expiry_date = user_data.expiry_date
    package_details = Radius.get_last_package(user_mac)

    socket =
      socket
      |> assign(:user_data, user_data)
      |> assign(:expiry_date, expiry_date)
      |> assign(:expired?, expired?(expiry_date))
      |> assign(:user_ip, user_ip)
      |> assign(:package_details, package_details)

    if expired?(expiry_date) do
      # MikroTik.add_disabled_user(user_ip)
      {:ok, push_redirect(socket, to: "/expired")}
    else
      {:ok, push_redirect(socket, to: "/dashboard")}
    end
  end

  def expired?(expiry_date) do
    DateTime.compare(expiry_date, DateTime.utc_now()) == :lt
  end

  def handle_event("renew_subscription", _params, socket) do
    {:noreply, push_redirect(socket, to: "/renew?mac=#{socket.assigns.user_data.mac_address}")}
  end

  def handle_event("buy_new", _params, socket) do
    {:noreply, push_redirect(socket, to: "/login")}
  end

  def render(assigns) do
    ~H"""
    <div class="expiry-page">
      <h1>Internet Access Expired</h1>
      <p>Your internet session has ended.</p>
      <p><strong>MAC Address:</strong> <%= @user_data.mac_address %></p>
      <p><strong>Package:</strong> <%= @package_details.package_name %></p>
      <p><strong>Hours Subscribed:</strong> <%= @package_details.hours %> Hours</p>
      <p><strong>Last Active:</strong> <%= @package_details.last_active %></p>
      <button phx-click="renew_subscription">Renew Subscription</button>
      <button phx-click="buy_new">Buy New Subscription</button>
    </div>
    """
  end
end
