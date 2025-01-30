defmodule QserveIspApi.Radacct do
  import Ecto.Query
  alias QserveIspApi.Repo

  # 1️⃣ Fetch Active Users
  def get_active_users do
    query =
      from r in "radacct",
        where: is_nil(r.acctstoptime),
        select: %{
          username: r.username,
          mac: r.callingstationid,
          nas_ipaddress: r.nasipaddress,
          active: true
        }

    Repo.all(query)
  end

  # 2️⃣ Get User Data Usage
  def get_user_data_usage(username) do
    query =
      from r in "radacct",
        where: r.username == ^username,
        select: %{
          username: r.username,
          total_download: sum(r.acctinputoctets),
          total_upload: sum(r.acctoutputoctets)
        }

    Repo.one(query)
  end

  # 3️⃣ Get Last Session Details
  def get_last_session(username) do
    query =
      from r in "radacct",
        where: r.username == ^username,
        order_by: [desc: r.acctstarttime],
        limit: 1,
        select: %{
          username: r.username,
          mac: r.callingstationid,
          start_time: r.acctstarttime,
          stop_time: r.acctstoptime,
          terminate_cause: r.acctterminatecause
        }

    Repo.one(query)
  end
end
