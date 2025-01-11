defmodule QserveIspApi.Repo do
  use Ecto.Repo,
    otp_app: :qserve_isp_api,
    adapter: Ecto.Adapters.MyXQL
end
