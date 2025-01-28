defmodule QserveIspApiWeb.VerifyPaymentLive do
  use QserveIspApiWeb, :live_view

  alias QserveIspApi.Payments
  alias QserveIspApi.Packages
  alias QserveIspApi.Radius

  def mount(params, _session, socket) do
    package = params["package"]
    mac = params["mac"]
    user_details = Packages.get_user_details(mac)
    {:ok, assign(socket, package: package, mac: mac, user_details: user_details, status: "Pending")}
  end

  def handle_info(:check_payment, socket) do
    case Payments.check_payment_status(socket.assigns.package) do
      :success ->
        #Add user to radcheck and radreply upon successful payment
        # FreeRadius.add_user_to_radius(socket.assigns.package, socket.assigns.mac)

        QserveIspApi.Radius.Radcheck.add_or_update_radcheck(socket.assigns.mac, socket.assigns.mac)
        QserveIspApi.Radius.Radreply.add_radreply_details(socket.assigns.mac, socket.assigns.package.duration)

        {:noreply, push_redirect(socket, to: Routes.live_path(socket, QserveIspApiWeb.DashboardLive))}
      :pending ->
        Process.send_after(self(), :check_payment, 5000)
        {:noreply, assign(socket, status: "Pending")}
      :failed ->
        {:noreply, assign(socket, status: "Failed")}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Verify Payment</h1>
      <p>Status: <%= @status %></p>
      <p>Processing for <%= @user_details.name %>...</p>
    </div>
    """
  end
end
