defmodule QserveIspApi.Payments do
    alias QserveIspApi.Repo
    alias QserveIspApi.Payments.Payment
    alias QserveIspApi.Packages.Packages
    alias QserveIspApi.Radreply
    alias QserveIspApi.MpesaClient  # Placeholder for the M-Pesa STK push logic

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
  end