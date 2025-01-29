defmodule QserveIspApiWeb.MakePaymentLive do
  use QserveIspApiWeb, :live_view

  # alias QserveIspApi.Payments
  alias QserveIspApi.Packages
  alias QserveIspApi.Repo
  alias QserveIspApi.User
  alias QserveIspApi.Payments.Payment
  alias QserveIspApi.MpesaApi
  alias QserveIspApi.MpesaTransactions.MpesaTransaction


  def mount(params, _session, socket) do
    package_id = params["package"]
    mac = params["mac"]
    username = params["username"]
    nas_ipaddress = params["nas_ipaddress"]

    package = Packages.get_package_details(package_id)
    # user = Repo.get_by(User, username: username)


    # {:ok, assign(socket, package: package, mac: mac, phone_number: "")}

    {:ok,
    assign(socket,
      package: package,
      mac: mac,
      username: username,
      nas_ipaddress: nas_ipaddress,
      phone_number: ""
    )}

  end

  # def handle_event("submit_payment", %{"phone_number" => phone_number}, socket) do
  #   # Initiate STK push
  #   # Payments.initiate_payment(phone_number, socket.assigns.package.id)
  #   # {:noreply, push_redirect(socket, to: Routes.live_path(socket, QserveIspApiWeb.VerifyPaymentLive, package: socket.assigns.package))}
  #   {:noreply,
  #   push_redirect(socket,
  #     to: ~p"/verify_payment/#{socket.assigns.mac}/#{socket.assigns.nas_ipaddress}?package=#{socket.assigns.package.id}"
  #   )}
  # end


  @impl true
  def handle_event(
      "process_payment",
      %{"phone_number" => phone, "package_id" => package_id, "price" => price, "mac" => mac, "username" => username},
      socket
    ) do
  with user <- Repo.get_by(User, username: username),
       amount <- Decimal.new(price) |> Decimal.to_integer(),
       transaction_description <- "Payment for package #{package_id}",
       {:ok, payment} <-
         Repo.transaction(fn ->
           %Payment{}
           |> Payment.changeset(%{
             user_id: user.id,
             package_id: String.to_integer(package_id),
             amount: amount,
             phone_number: phone,
             status: "pending",
             username: username,
             account_reference: mac,
             transaction_description: transaction_description
           })
           |> Repo.insert()
         end) do

    # Now correctly access payment.id inside the `with` block
    case MpesaApi.send_stk_push(
           user.id,
           payment.id,  # ✅ Fix: payment is now correctly accessible
           amount,
           phone,
           mac,
           transaction_description
         ) do
      {:ok, response} ->
        Repo.insert!(%MpesaTransaction{
          user_id: user.id,
          payment_id: payment.id,
          checkout_request_id: response["CheckoutRequestID"],
          merchant_request_id: response["MerchantRequestID"],
          status: "initiated",
          raw_response: response
        })

        {:noreply, push_redirect(socket, to: ~p"/verify_payment/#{username}/#{mac}?payment_id=#{payment.id}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to send STK push: #{reason}")}
    end
  else
    {:error, reason} -> {:noreply, put_flash(socket, :error, "Payment initiation failed: #{reason}")}
    _ -> {:noreply, put_flash(socket, :error, "Unexpected error occurred")}
  end
end



#   @impl true
#   def handle_event(
#       "process_payment",
#       %{"phone_number" => phone, "package_id" => package_id, "price" => price, "mac" => mac, "username" => username},
#       socket
#     ) do
#   user = Repo.get_by(User, username: username)
#   # amount = Decimal.new(price)
#    amount =
#       case Decimal.new(price) do
#         %Decimal{} = decimal -> Decimal.to_integer(decimal)
#         _ -> 0 # Handle invalid price inputs gracefully
#       end
#   transaction_description = "Payment for package #{package_id}"

#   Repo.transaction(fn ->
#     # Step 1: Save payment in the payments table
#     {:ok, payment} =
#       %Payment{}
#       |> Payment.changeset(%{
#         user_id: user.id,
#         package_id: String.to_integer(package_id),
#         amount: amount,
#         phone_number: phone,
#         status: "pending",
#         username: mac,
#         account_reference: mac,
#         transaction_description: transaction_description

#       })
#       |> Repo.insert()

#     # Step 2: Send STK push


#     stk_response =
#       case MpesaApi.send_stk_push(
#              user.id,
#              payment.id,
#              amount,
#              phone,
#              mac,
#              transaction_description
#            ) do
#         {:ok, response} ->
#           response

#         {:error, reason} ->
#           raise "Failed to send STK push: #{reason}"
#       end

#     # Step 3: Save STK push response in mpesa_transactions table
#     # Repo.insert!(%MpesaTransaction{
#     #       user_id:  user.id,
#     #       payment_id: payment.id,
#     #       checkout_request_id: stk_response["CheckoutRequestID"],
#     #       merchant_request_id: stk_response["MerchantRequestID"],
#     #       status: "initiated",
#     #       raw_response: stk_response
#     #     })
#       end)

#   # {:noreply,
#   #  assign(socket, :payment_status, "STK push sent successfully! Please wait for confirmation.")
#   # }
#   {:noreply,
#   push_redirect(socket,
#     to: ~p"/verify_payment/#{username}/#{mac}?payment_id=#{payment.id}"
#   )}

# end

# */

  def render(assigns) do
    ~H"""
    <div>
      <h1>Make Payment</h1>
      <p>Package: <%= @package.name %> - Price: <%= @package.price %></p>

      <form style="margin-top: 12px;" phx-submit="process_payment">
        <input
          type="tel"
          name="phone_number"
          placeholder="Enter phone number"
          required
          style="width: 100%; padding: 8px; margin-bottom: 8px; border: 1px solid #ccc; border-radius: 4px;">
        <input type="text" name="package_id" value={ @package.id }>
        <input type="text" name="price" value={ @package.price }>
        <input type="text" name="mac" value={@mac }>
        <input type="text" name="username" value={@username }>
        <button
          type="submit"
          style="padding: 8px 16px; background-color: #28a745; color: white; border: none; border-radius: 4px;">
          Pay NOW
        </button>
      </form>

      <%!-- <form phx-submit="submit_payment">
        <label for="phone_number">Enter Phone Number:</label>
        <input type="text" name="phone_number" id="phone_number" value={@phone_number } required />
        <button type="submit">Pay Now---</button>
      </form> --%>
    </div>
    """
  end
end
