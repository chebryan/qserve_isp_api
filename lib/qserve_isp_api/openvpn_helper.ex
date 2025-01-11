defmodule QserveIspApi.OpenvpnHelper do
  alias QserveIspApi.{Repo, Openvpn}
  require Logger
  @cert_dir "/etc/openvpn"

  @doc """
  Generates OpenVPN files (crt, key, ca) for the given IP address.
  Saves files in /etc/openvpn and stores the details in the `openvpn` table.
  """
  def generate_openvpn_files(ip) do
    crt_path = Path.join(@cert_dir, "#{ip}.crt")
    key_path = Path.join(@cert_dir, "#{ip}.key")
    ca_path = Path.join(@cert_dir, "ca.crt")

    # Generate certificates and keys using OpenSSL
    {crt, key, ca} = generate_cert_and_key(ip)
    ca = File.read!(ca_path)

    # Write the generated files to /etc/openvpn
    File.write!(crt_path, crt)
    File.write!(key_path, key)

    # Save details to the database
    openvpn_params = %{
      "ip" => ip,
      "crt" => crt,
      "key" => key,
      "ca" => ca
    }

    changeset = Openvpn.changeset(%Openvpn{}, openvpn_params)

    case Repo.insert(changeset) do
      {:ok, openvpn} -> {:ok, openvpn}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # defp generate_cert_and_key(ip) do
  #   # Replace this with actual OpenSSL commands or library calls
  #   crt = "FAKE CERTIFICATE CONTENT FOR #{ip}"
  #   key = "FAKE KEY CONTENT FOR #{ip}"

  #   {crt, key}
  # end
  defp generate_cert_and_key(ip) do
    cert_dir = "~/openvpn-ca" |> Path.expand()
    openvpn_dir = "/etc/openvpn"
    client_name = ip

    # Paths to the existing inline file and related files
    inline_path = Path.join(cert_dir, "pki/inline/#{client_name}.inline")
    req_path = Path.join(cert_dir, "pki/reqs/#{client_name}.req")
    crt_path = Path.join(cert_dir, "pki/issued/#{client_name}.crt")
    key_path = Path.join(cert_dir, "pki/private/#{client_name}.key")
    ca_path = Path.join(cert_dir, "pki/ca.crt")

    # Remove existing files if they exist
    for file <- [inline_path, req_path, crt_path, key_path] do
      if File.exists?(file) do
        Logger.debug("Removing existing file: #{file}")
        File.rm!(file)
      end
    end

    # Run the EasyRSA command to generate certificates and keys
    command = "cd #{cert_dir} && echo yes | ./easyrsa build-client-full #{client_name} nopass"

    Logger.debug("Running command: #{command}")
    {output, exit_code} = System.cmd("bash", ["-c", command])

    if exit_code != 0 do
      raise "Error generating certificates: #{output}"
    end

    # Read the generated files
    crt = File.read!(crt_path)
    key = File.read!(key_path)
    ca = File.read!(ca_path)

    # Copy the files to /etc/openvpn
    File.cp!(crt_path, Path.join(openvpn_dir, "#{client_name}.crt"))
    File.cp!(key_path, Path.join(openvpn_dir, "#{client_name}.key"))
    File.cp!(ca_path, Path.join(openvpn_dir, "ca.crt"))

    {crt, key, ca}
  end








  def check_nas_status(ip_address) do
    case :gen_tcp.connect(String.to_charlist(ip_address), 1812, [:binary, active: false], 5000) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        {:ok, "Online"}
      {:error, _reason} ->
        {:error, "Offline"}
    end
  end
end
