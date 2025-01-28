defmodule QserveIspApiWeb.MakePaymentLive do
  use QserveIspApiWeb, :live_view

  alias QserveIspApi.Payments
  alias QserveIspApi.Packages


  def mount(params, _session, socket) do
    package_id = params["package"]
    mac = params["mac"]
    nas_ipaddress = params["nas_ipaddress"]
    package = Packages.get_package_details(package_id)


    # {:ok, assign(socket, package: package, mac: mac, phone_number: "")}

    {:ok,
    assign(socket,
      package: package,
      mac: mac,
      nas_ipaddress: nas_ipaddress
    )}

  end

  def handle_event("submit_payment", %{"phone_number" => phone_number}, socket) do
    # Initiate STK push
    Payments.initiate_payment(phone_number, socket.assigns.package.id)
    # {:noreply, push_redirect(socket, to: Routes.live_path(socket, QserveIspApiWeb.VerifyPaymentLive, package: socket.assigns.package))}
    {:noreply,
    push_redirect(socket,
      to: ~p"/verify_payment/#{socket.assigns.mac}/#{socket.assigns.nas_ipaddress}?package=#{socket.assigns.package.id}"
    )}
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
