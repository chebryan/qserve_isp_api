defmodule QserveIspApiWeb.NasController do
  use QserveIspApiWeb, :controller
  import Ecto.Query # Import Ecto.Query for using `from/2`
  require Logger
  alias QserveIspApiWeb.Utils.AuthUtils

  alias QserveIspApi.{Repo, Nas, Auth.JWT}
    alias QserveIspApi.VPNUser


  # @ip_pool "172.20." # Starting IP pool for auto-generation
  @secret_length 10 # Length of the secret

  @doc """
  Create a new NAS for the authenticated user.
  """
  def create(conn, %{"nas_name" => nas_name, "description" => description}) do
    case extract_user_id(conn) do
      {:ok, user_id} ->
        # Auto-generate IP and secret
        ip = generate_ip()
        secret = generate_secret()

        # Insert the NAS

        # changeset = Nas.changeset(%Nas{}, nas_params)

        # case Repo.insert(changeset) do
        #   {:ok, nas} ->
        #     json(conn, %{
        #       message: "NAS created successfully",
        #       data: nas
        #     })

        #   {:error, changeset} ->
        #     json(conn, %{
        #       error: "Failed to create NAS",
        #       details: translate_errors(changeset)
        #     })
        # end
          # Generate OpenVPN files
      case QserveIspApi.OpenvpnHelper.generate_openvpn_files(ip) do
        {:ok, _params} ->
          # Insert the NAS
          nas_params = %{
            "nasname" => nas_name,
            "shortname" => nas_name,
            "description" => description,
            "server" => ip,
            "secret" => secret,
            "user_id" => user_id,
            "port" => 3799
          }

          case Repo.insert(Nas.changeset(%Nas{}, nas_params)) do
            {:ok, nas} ->
              json(conn, %{message: "NAS created successfully", data: nas})

            {:error, changeset} ->
              json(conn, %{error: "Failed to create NAS", details: translate_errors(changeset)})
          end

        {:error, changeset} ->
          json(conn, %{error: "Failed to generate OpenVPN files", details: translate_errors(changeset)})
      end

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  @doc """
  Extract user_id from the Authorization token.
  """
  defp extract_user_id(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case JWT.verify_token(token) do
          {:ok, claims} -> {:ok, claims["user_id"]}
          {:error, _reason} -> {:error, "Invalid or expired token"}
        end

      _ ->
        {:error, "Authorization token not provided"}
    end
  end

  @doc """
  Auto-generate an IP address for the NAS.
  """
  # defp generate_ip do
  #   last_octet = :rand.uniform(254) # Generate a random number between 1 and 254
  #   "#{@ip_pool}#{last_octet}"
  # end

  defp generate_ip do
    case Repo.all(from n in Nas, order_by: [desc: n.server], limit: 1, select: n.server) do
      [last_ip] when is_binary(last_ip) ->
        next_ip(last_ip)

      [] ->
        # If no IP exists, start with the first IP in the pool
        "172.20.0.4"
    end
  end


  defp next_ip(last_ip) do
    case String.split(last_ip, ".") do
      [a, b, c, d] ->
        last_octet = String.to_integer(d)
        second_last_octet = String.to_integer(c)

        cond do
          last_octet < 254 ->
            # Increment the last octet
            "#{a}.#{b}.#{second_last_octet}.#{last_octet + 1}"

          second_last_octet < 254 ->
            # Reset last octet and increment the second-to-last octet
            "#{a}.#{b}.#{second_last_octet + 1}.1"

          true ->
            raise "IP pool exhausted. Consider increasing the pool range."
        end

      _ ->
        raise "Invalid IP format in database: #{last_ip}"
    end
  end

  defp next_ip(nil), do: "172.20.0.4"




  @doc """
  Auto-generate a secret for the NAS.
  """
  # defp generate_secret do
  #   :crypto.strong_rand_bytes(@secret_length)
  #   |> Base.encode64()
  #   |> binary_part(0, @secret_length)
  # end

  defp generate_secret do
    allowed_characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    length = 10

    for _ <- 1..length, into: "" do
      String.at(allowed_characters, :rand.uniform(String.length(allowed_characters)) - 1)
    end
  end

  @doc """
  Translate changeset errors for better readability.
  """
  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def certificates(conn, %{"ip" => ip}) do
    case get_certificates(ip) do
      {:ok, certificates} ->
        json(conn, %{status: "success", certificates: certificates})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", reason: reason})
    end
  end

  defp get_certificates(ip) do
    # Validate the IP
    case :inet.parse_address(to_charlist(ip)) do
      {:ok, _parsed_ip} ->
        # Here you'd implement the logic to retrieve certificates from the NAS.
        # For example, using SSH, API calls, or another mechanism:
        case retrieve_certificates_from_nas(ip) do
          {:ok, certs} -> {:ok, certs}
          {:error, reason} -> {:error, reason}
        end

      {:error, _} ->
        {:error, "Invalid IP address"}
    end
  end

  defp retrieve_certificates_from_nas(ip) do
    # Example: Simulate fetching certificates
    {:ok, ["certificate1.pem", "certificate2.pem"]}
  end

  def openvpn_files(conn, %{"ip" => ip}) do
    case fetch_and_zip_openvpn_files(ip) do
      {:ok, zip_path} ->
         zip_filename = "Qserve-isp-#{ip}.zip"
        conn
        |> put_resp_content_type("application/zip")
        |> put_resp_header("content-disposition", "attachment; filename=\"#{zip_filename}\"")
        |> send_file(200, zip_path)
        |> halt()
      # File.rm(zip_path)


      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", reason: reason})
    end
  end

  def fetch_and_zip_openvpn_files(ip) do
    Logger.debug("Fetching and zipping OpenVPN files for IP: #{ip}")

    # Define file paths
    crt_path = "/etc/openvpn/#{ip}.crt"
    key_path = "/etc/openvpn/#{ip}.key"
    ca_path = "/etc/openvpn/ca.crt"
    zip_path = "/tmp/Qserve-isp-#{ip}.zip"

    # Log file existence
    Logger.debug("Paths: crt=#{crt_path}, key=#{key_path}, ca=#{ca_path}, zip=#{zip_path}")

    # Ensure all required files exist
    if File.exists?(crt_path) and File.exists?(key_path) and File.exists?(ca_path) do
      # Create a zip file
      zip_result = System.cmd("zip", ["-j", zip_path, crt_path, key_path, ca_path])
      Logger.debug("Zip result: #{inspect(zip_result)}")

      # Check if the zip file was created successfully
      if File.exists?(zip_path) do
        {:ok, zip_path}
      else
        {:error, "Failed to create zip file"}
      end
    else
      missing_files = Enum.filter([crt_path, key_path, ca_path], &!File.exists?(&1))
      Logger.error("Missing files: #{inspect(missing_files)}")
      {:error, "Missing required files: #{inspect(missing_files)}"}
    end
  end

  # defp fetch_and_zip_openvpn_files(ip) do
  #   base_path = "/etc/openvpn"
  #   file_names = ["ca.crt", "#{ip}.crt", "#{ip}.key"]

  #   # Verify that the requested files exist
  #   files =
  #     file_names
  #     |> Enum.map(&Path.join(base_path, &1))
  #     |> Enum.filter(&File.exists?/1)

  #   if length(files) != length(file_names) do
  #     {:error, "One or more files not found"}
  #   else
  #     # Generate a temporary ZIP file
  #      zip_path = "/tmp/Qserve-isp-#{ip}.zip"

  #     case :zip.create(zip_path, files, [:memory]) do
  #       {:ok, _} -> {:ok, zip_path}
  #       {:error, reason} -> {:error, reason}
  #     end
  #   end
  # end



    @doc """
  Inserts a record into the radcheck table.
  Expects `username` and `value` (password) in the request parameters.
  """
  def insert_radcheck(conn, %{"username" => username, "value" => value}) do
    changeset =
      %VPNUser{}
      |>VPNUser.changeset(%{username: username, value: value})

    case Repo.insert(changeset) do
      {:ok, _record} ->
        conn
        |> put_status(:created)
        |> json(%{status: "success", message: "Record inserted into radcheck successfully."})

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", errors: changeset.errors})
    end
  end


end
