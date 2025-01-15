defmodule QserveIspApiWeb.HotspotLive do
  use Phoenix.LiveView
  alias QserveIspApi.Packages
  alias QserveIspApi.Repo
  alias QserveIspApi.User
  alias QserveIspApi.Payments.Payment
  alias QserveIspApi.MpesaApi

  @impl true
  def mount(_params, _session, socket) do
    # Return {:ok, socket} with initial assigns
    {:ok,
     assign(socket,
       packages: [],
       user: nil,
       active_package_id: nil,
       phone_number: nil,
       mac: nil
     )}
  end
  # def mount(_params, _session, socket) do
  #   {:ok,
  #    socket
  #    |> assign(:packages, [])
  #    |> assign(:user, nil)
  #    |> assign(:active_package_id, nil)
  #    |> assign(:phone_number, nil)}
  #    |> assign(:mac, nil)
  # end

  @impl true
  def handle_params(params, _uri, socket) do
    # Extract username, nas_ipaddress, and mac
    username = params["username"]
    nas_ip = params["nas_ipaddress"]
    # mac = get_mac_from_url(params["nas_ipaddress"])
    mac = "testuser1" #params["mac"]
    # Fetch user
    user = Repo.get_by(User, username: username)

    # Fetch packages for NAS IP
    packages = Packages.list_packages_for_nas_ip(nas_ip)
    IO.inspect(nas_ip, label: "=============================")
    IO.inspect(mac, label: "=========+++MAC====================")
    IO.inspect(username, label: "=========+++USERNAME====================")
    {:noreply, assign(socket, user: user, packages: packages, mac: mac)}

  end

  # @impl true
  # def handle_params(%{"username" => username, "nas_ipaddress" => nas_ip}, _uri, socket) do
  #   # Fetch the user
  #   user =
  #     Repo.get_by(User, username: username)
  #     |> case do
  #       nil -> nil
  #       user -> user
  #     end

  #   # Fetch packages for the NAS IP
  #   packages =
  #     Packages.list_packages_for_nas_ip(nas_ip)

  #   {:noreply, assign(socket, user: user, packages: packages)}
  # end

  @impl true
  def handle_event("show_phone_input", %{"package-id" => package_id}, socket) do
    {:noreply, assign(socket, active_package_id: String.to_integer(package_id))}
  end

  @impl true
  def handle_event("process_payment", %{"phone_number" => phone, "package_id" => package_id, "price" => price, "mac" => mac}, socket) do
    user = socket.assigns.user
    amount = Decimal.new(price)
    account_reference = mac
    transaction_description = "Payment for package #{package_id}"

    # Save the payment record
    payment_changeset =
      Payment.changeset(%Payment{}, %{
        user_id: user.id,
        package_id: package_id,
        username: mac,
        amount: amount,
        phone_number: phone,
        status: "pending",
        account_reference: account_reference,
        transaction_description: transaction_description
      })

    case Repo.insert(payment_changeset) do
      {:ok, payment} ->
        # Call the M-Pesa STK push
        case MpesaApi.send_stk_push(
               user.id,
               payment.id,
               amount,
               phone,
               account_reference,
               transaction_description
              # 1, # user_id
              # payment.id, # payment_id
              # 100.0, # amount
              # "254700000000", # phone_number
              # "unique_mac_address", # account_reference
              # "Payment for internet" # transaction_description
             ) do
          {:ok, response} ->
            {:noreply, assign(socket, :payment_status, "STK push sent successfully!")}

          {:error, reason} ->
            IO.inspect(reason, label: "STK push error")
            {:noreply, assign(socket, :payment_status, "Failed to send STK push.")}
        end

      {:error, changeset} ->
        {:noreply,
         assign(socket, :payment_status, "Failed to save payment record. Check your input.")}
    end
  end

  # @impl true
  # def handle_event("process_payment", %{"phone_number" => phone, "package_id" => package_id, "price" => price, "mac" => mac}, socket) do
  #   user = socket.assigns.user

  #   # Prepare payment data
  #   amount = Decimal.new(price)
  #   transaction_description = "Payment for package #{package_id}"
  #   account_reference = mac

  #   case QserveIspApi.MpesaApi.initiate_payment(user.id, package_id, amount, phone, account_reference, transaction_description) do
  #     {:ok, payment} ->
  #       {:noreply, assign(socket, active_package_id: nil, phone_number: nil)}

  #     {:error, reason} ->
  #       IO.inspect(reason, label: "Payment initiation failed")
  #       {:noreply, socket}
  #   end
  # end



  defp get_mac_from_url(url) do
    # Extract MAC address using a regular expression
    case Regex.run(~r/\$\(mac\)/, url) do
      nil -> nil
      [mac] -> String.trim(mac)
    end
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2>Welcome, <%= @user.username %>!</h2>

      <h3>Available Packages</h3>
      <%= if Enum.empty?(@packages) do %>
        <p>No packages available for this NAS.</p>
      <% else %>
        <div style="display: flex; flex-wrap: wrap; gap: 16px;">
          <%= for package <- @packages do %>
            <div style="
              flex: 0 0 calc(33.333% - 16px);
              border: 1px solid #ccc;
              border-radius: 8px;
              padding: 16px;
              box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);">
              <h4><%= package.name %></h4>
              <p><strong>Description:</strong> <%= package.description %></p>
              <p><strong>Duration:</strong> <%= package.duration %> seconds</p>
              <p><strong>Price:</strong> Ksh<%= package.price %></p>

              <button
                style="margin-top: 12px; padding: 8px 16px; background-color: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer;"
                phx-click="show_phone_input"
                phx-value-package-id={ package.id }>
                Buy
              </button>

              <%= if @active_package_id == package.id do %>
                <form style="margin-top: 12px;" phx-submit="process_payment">
                  <input
                    type="tel"
                    name="phone_number"
                    placeholder="Enter phone number"
                    required
                    style="width: 100%; padding: 8px; margin-bottom: 8px; border: 1px solid #ccc; border-radius: 4px;">
                  <input type="hidden" name="package_id" value={ package.id }>
                  <input type="hidden" name="price" value={ package.price }>
                  <input type="hidden" name="mac" value={@mac }>

                  <button
                    type="submit"
                    style="padding: 8px 16px; background-color: #28a745; color: white; border: none; border-radius: 4px;">
                    Submit
                  </button>
                </form>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

end
