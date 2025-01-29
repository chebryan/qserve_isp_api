defmodule QserveIspApiWeb.DashboardLive do
  use QserveIspApiWeb, :live_view

  alias QserveIspApi.{Packages, Payments, Users, Wallet}
  alias QserveIspApi.Repo

  def mount(%{"mac" => mac}, _session, socket) do
    case Packages.get_user_details(mac) do
      nil ->
        {:ok, push_redirect(socket, to: "/login")}

      user_details ->
        {:ok, assign(socket, user_details: user_details, loading: true)}
    end
  end

  def handle_params(%{"mac" => mac}, _uri, socket) do
    user_details = Packages.get_user_details(mac)
    data_usage = Packages.get_user_data_usage(mac)
    package = Packages.get_user_package(mac)
    wallet_balance = Wallet.get_balance(user_details.username)

    {:noreply,
     assign(socket,
       user_details: user_details,
       data_usage: data_usage,
       package: package,
       wallet_balance: wallet_balance,
       loading: false
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-6">
      <h1 class="text-2xl font-bold">Dashboard</h1>

      <div :if={@loading}>
        <p>Loading user details...</p>
      </div>

      <div :if={!@loading}>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <p><strong>Username (MAC):</strong> <%= @user_details.mac %></p>
            <p><strong>Status:</strong> <%= if @user_details.active, do: "Active", else: "Expired" %></p>
            <p><strong>Device Name:</strong> <%= @user_details.device_name || "Unknown" %></p>
            <p><strong>Package Name:</strong> <%= @package.name || "N/A" %></p>
          </div>
          <div>
            <p><strong>Upload Data:</strong> <%= @data_usage.upload_mb %> MB</p>
            <p><strong>Download Data:</strong> <%= @data_usage.download_mb %> MB</p>
            <p><strong>Expiry Date:</strong> <%= @user_details.expiry_date || "N/A" %></p>
            <p><strong>Wallet Balance:</strong> <%= @wallet_balance %> KES</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
