defmodule QserveIspApi.Mpesa do
  alias QserveIspApi.Repo
  alias QserveIspApi.Mpesa.Credential

  @static_config Application.compile_env(:qserve_isp_api, :mpesa)

  def fetch_credentials(user_id) do
    Repo.get_by(Credential, user_id: user_id)
  end

  def static_config, do: @static_config
end
