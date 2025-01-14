defmodule QserveIspApiWeb.Plugs.Authenticate do
  @moduledoc """
  A plug to authenticate requests using a JWT.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias QserveIspApi.Auth.JWT

  @doc false
  def init(opts), do: opts

  @doc """
  This function checks the `Authorization` header for a valid Bearer token.
  If the token is valid, it assigns the user claims to the connection.
  Otherwise, it returns a 401 Unauthorized response.
  """
  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        verify_token(conn, token)

      _ ->
        unauthorized_response(conn)
    end
  end

  defp verify_token(conn, token) do
    case JWT.verify_token(token) do
      {:ok, claims} ->
        assign(conn, :current_user, claims)

      {:error, _reason} ->
        unauthorized_response(conn)
    end
  end

  defp unauthorized_response(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Unauthorized"})
    |> halt()
  end

  def extract_user_id(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case JWT.verify_token(token) do
          {:ok, claims} -> {:ok, claims["user_id"]}
          {:error, _reason} -> {:error, "Invalid or expired token"}
        end

      _ ->
        {:error, "Authorization token not provided"}
    end
  end



end
