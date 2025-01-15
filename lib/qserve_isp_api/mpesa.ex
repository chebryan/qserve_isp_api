defmodule QserveIspApi.Mpesa do
  alias QserveIspApi.Repo
  alias QserveIspApi.Mpesa.Credential

  @static_config Application.compile_env(:qserve_isp_api, :mpesa)

  def fetch_credentials(user_id) do
    Repo.get_by(Credential, user_id: user_id)
  end

  def add_or_update_credentials(attrs) do
    Repo.transaction(fn ->
      case Repo.get_by(Credential, user_id: attrs["user_id"]) do
        nil ->
          %Credential{}
          |> Credential.changeset(attrs)
          |> Repo.insert()

        credential ->
          credential
          |> Credential.changeset(attrs)
          |> Repo.update()
      end
    end)
  end


  def static_config, do: @static_config
end
