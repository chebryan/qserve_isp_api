defmodule QserveIspApiWeb.RadacctController do
  use QserveIspApiWeb, :controller

  alias QserveIspApi.Radacct

  # 1️⃣ Get Active Users
  def active_users(conn, _params) do
    users = Radacct.get_active_users()
    json(conn, %{status: "success", data: users})
  end

  # 2️⃣ Get User Data Usage
  def user_data_usage(conn, %{"username" => username}) do
    case Radacct.get_user_data_usage(username) do
      nil -> json(conn, %{status: "error", message: "User not found"})
      data -> json(conn, %{status: "success", data: data})
    end
  end

  # 3️⃣ Get Last Session Details
  def last_session(conn, %{"username" => username}) do
    case Radacct.get_last_session(username) do
      nil -> json(conn, %{status: "error", message: "No session found"})
      session -> json(conn, %{status: "success", data: session})
    end
  end
end
