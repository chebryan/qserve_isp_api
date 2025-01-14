defmodule QserveIspApiWeb.Utils.AuthUtils do
    alias QserveIspApi.Auth.JWT
    @doc """
    Extracts the user ID from the authorization token in the connection headers.

    ## Parameters
      - conn: The Plug connection.

    ## Returns
      - {:ok, user_id} on success
      - {:error, reason} on failure
    """
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
