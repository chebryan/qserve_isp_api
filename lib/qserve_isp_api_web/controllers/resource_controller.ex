defmodule QserveIspApiWeb.ResourceController do
  use QserveIspApiWeb, :controller

  def index(conn, _params) do
    current_user = conn.assigns[:current_user]
    json(conn, %{data: "Welcome, #{current_user["username"]}. This is a protected resource."})
  end
end
