defmodule QserveIspApiWeb.MakePaymentLive do
  use QserveIspApiWeb, :live_view

  alias QserveIspApi.Payments

  def mount(params, _session, socket) do
    package = params["package"]
    mac = params["mac"]
    {:ok, assign(socket, package: package, mac: mac, phone_number: "")}
  end

  def handle_event("submit_payment", %{"phone_number" => phone_number}, socket) do
    # Initiate STK push
    Payments.initiate_payment(phone_number, socket.assigns.package.id)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, QserveIspApiWeb.VerifyPaymentLive, package: socket.assigns.package))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Make Payment</h1>
      <p>Package: <%= @package.name %> - Price: <%= @package.price %></p>
      <form phx-submit="submit_payment">
        <label for="phone_number">Enter Phone Number:</label>
        <input type="text" name="phone_number" id="phone_number" value={@phone_number } required />
        <button type="submit">Pay Now</button>
      </form>
    </div>
    """
  end
end
