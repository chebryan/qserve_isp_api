defmodule QserveIspApi.Payments do
    alias QserveIspApi.Repo
    alias QserveIspApi.Payments.Payment
    alias QserveIspApi.Packages.Packages
    alias QserveIspApi.Radius.Radreply
    alias QserveIspApi.MpesaClient  # Placeholder for the M-Pesa STK push logic
    import Ecto.Query, warn: false
    @doc """
    Creates a payment record for a package.
    """
    def initiate_payment(attrs) do
      package = Packages.get_package!(attrs.package_id)

      changeset =
        %Payment{}
        |> Payment.changeset(Map.merge(attrs, %{
          amount_paid: package.price,
          payment_status: :pending
        }))

      case Repo.insert(changeset) do
        {:ok, payment} ->
          send_stk_push(payment, attrs.phone_number)
          {:ok, payment}

        {:error, changeset} ->
          {:error, changeset}
      end
    end

    # def initiate_payment_(phone_number, package_id) do
    #   package = Packages.get_package!(package_id)

    #   changeset =
    #     %Payment{}
    #     |> Payment.changeset(Map.merge(attrs, %{
    #       amount_paid: package.price,
    #       payment_status: :pending
    #     }))

    #   case Repo.insert(changeset) do
    #     {:ok, payment} ->
    #       send_stk_push(payment, attrs.phone_number)
    #       {:ok, payment}

    #     {:error, changeset} ->
    #       {:error, changeset}
    #   end
    # end

    def mark_payment_as_successful(payment_id) do
      payment = Repo.get!(Payment, payment_id)

      Repo.transaction(fn ->
        # Update payment status
        Repo.update!(Ecto.Changeset.change(payment, %{status: "completed"}))

        # Add to radcheck and radreply
        QserveIspApi.Radius.Radcheck.add_or_update_radcheck(payment.account_reference, generate_secret())
        QserveIspApi.Radius.Radreply.add_radreply_details(payment.account_reference, 86400)
      end)
    end

    def mark_payment_as_failed(payment_id) do
      payment = Repo.get!(Payment, payment_id)
      Repo.update!(Ecto.Changeset.change(payment, %{status: "failed"}))
    end

    defp generate_secret do
      :crypto.strong_rand_bytes(12) |> Base.encode64() |> binary_part(0, 12)
    end

    def check_payment_status(mac, package_id) do
      payment_status = Repo.get_by("payment", %{mac: mac, package_id: package_id})
      if payment_status && payment_status.status == "completed" do
        :success
      else
        :pending
      end
    end


    # def add_user_to_radius(package, mac) do
    #   username = "user_#{mac}"
    #         check_payment_status
    #             Repo.insert!(%{
    #               table: "radcheck",
    #               attributes: %{username: mac, attribute: "Cleartext-Password", op: ":=", value: mac}
    #             })

    #             Repo.insert!(%{
    #               table: "radreply",
    #               attributes: %{username: mac, attribute: "Framed-IP-Address", op: ":=", value: "192.168.1.100"}
    #             })
    #           end

    @doc """
    Handles the M-Pesa callback and updates payment status.
    """
    def handle_payment_callback(%{
          "ResultCode" => 0,
          "MpesaReceiptNumber" => mpesa_code,
          "PhoneNumber" => phone_number
        }) do
      Repo.transaction(fn ->
        payment =
          Repo.get_by!(Payment,
            mpesa_code: nil,
            payment_status: :pending
          )

        Repo.update!(Ecto.Changeset.change(payment, %{
          payment_status: :success,
          mpesa_code: mpesa_code
        }))

        activate_user(payment.username, payment.package_id)
      end)
    end

    # send_stk_push(user_id, payment_id, amount, phone_number, account_reference, transaction_description)

    defp send_stk_push(payment, phone_number) do
      MpesaClient.stk_push(%{
        phone_number: phone_number,
        amount: payment.amount_paid,
        callback_url: "https://example.com/api/payments/callback"
      })
    end

    defp activate_user(username, package_id) do
      package = Packages.get_package!(package_id)

      Repo.insert(%Radreply{
        username: username,
        attribute: "Session-Timeout",
        value: "#{package.duration}"
      })
    end

    # def check_payment_status(mac, package_id) do
    #   payment_status = Repo.get_by("payment", %{mac: mac, package_id: package_id})
    #   if payment_status && payment_status.status == "completed" do
    #     :success
    #   else
    #     :pending
    #   end
    # end



    @doc """
    List all payments.
    """
    def list_payments do
      Repo.all(Payment)
    end

    @doc """
    Get a payment by ID.
    """
    def get_payment!(id), do: Repo.get!(Payment, id)

    # def list_user_payments!(user_id), do: Repo.get!(Payment,user_id)

    def list_user_payments(user_id) do
      Repo.get!(Payment, user_id)
    end

    @doc """
    Create a new payment.
    """
    def create_payment(attrs \\ %{}) do
      %Payment{}
      |> Payment.changeset(attrs)
      |> Repo.insert()
    end

    @doc """
    Update an existing payment.
    """
    def update_payment(%Payment{} = payment, attrs) do
      payment
      |> Payment.changeset(attrs)
      |> Repo.update()
    end

    # def list_user_payments(user_id) do
    #   Repo.all(
    #     from p in Payment,
    #     where: p.user_id == ^user_id,
    #     order_by: [desc: p.inserted_at]
    #   )
    # end

    # def check_payment_status(mac, package_id) do
    #   query =
    #     from p in Payment,  # Use the correct schema reference
    #       where: p.account_reference == ^mac and p.package_id == ^package_id,
    #       select: %{status: p.status},  # Explicitly select the field
    #       order_by: [desc: p.inserted_at],
    #       limit: 1

    #   case Repo.one(query) do
    #     %{status: "completed"} -> {:ok, :success}
    #     %{status: "pending"} -> {:ok, :pending}
    #     %{status: "failed"} -> {:error, :failed}
    #     nil -> {:error, :not_found}
    #   end
    # end


    # def get_payment_by_mac_and_package(mac, package_id) do
    #   query =
    #     from p in Payment,
    #       where: p.account_reference == ^mac and p.package_id == ^package_id,
    #       order_by: [desc: p.inserted_at],
    #       limit: 1

    #   Repo.one(query)
    # end

    def get_payment_status(payment_id) do
      case Repo.get(Payment, payment_id) do
        %Payment{status: status} -> status
        nil -> "failed"
      end
    end

  end
