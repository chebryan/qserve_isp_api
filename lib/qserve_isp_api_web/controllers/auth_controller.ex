defmodule QserveIspApiWeb.AuthController do
  use QserveIspApiWeb, :controller

  alias QserveIspApi.Repo
  alias QserveIspApi.User
  alias QserveIspApi.Auth.JWT

  Logger.configure(level: :debug)

  @doc """
  Registers a new user.
  """
  def register(conn, %{
        "username" => username,
        "password" => password,
        "email" => email,
        "phone" => phone
      }) do
    user_params = %{
      username: username,
      password: password,
      email: email,
      phone: phone,
      nas_limit: 0 # Default value for NAS limit
    }

    changeset = User.changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{
          message: "User registered successfully",
          user: %{
            id: user.id,
            username: user.username,
            email: user.email
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Failed to register user", details: format_changeset_errors(changeset)})
    end
  end

  @doc """
  Logs in a user and returns a JWT token.
  """

  # def login(conn, %{"username" => username, "password" => password}) do
  #   require Logger

  #   Logger.debug("Login attempt started...")
  #   Logger.debug("Provided Username: #{username}")
  #   Logger.debug("Provided Password: #{password}")

  #   case Repo.get_by(User, username: username) do
  #     %User{password_hash: hash} = user ->
  #       Logger.debug("Stored Password Hash: #{hash}")

  #       if Bcrypt.verify_pass(password, hash) do
  #         Logger.debug("Password verified successfully!")
  #         {:ok, token, _claims} = JWT.generate_token(user)
  #         json(conn, %{token: token})
  #       else
  #         Logger.debug("Password verification failed!")
  #         unauthorized_response(conn)
  #       end

  #     nil ->
  #       Logger.debug("User not found!")
  #       unauthorized_response(conn)
  #   end
  # end

  # defp unauthorized_response(conn) do
  #   conn
  #   |> put_status(:unauthorized)
  #   |> json(%{error: "Invalid username or password"})
  # end

  def login(conn, %{"username" => username, "password" => password}) do
    case Repo.get_by(User, username: username) do
      %User{password_hash: hash} = user ->
        IO.inspect(hash, label: "Stored Password Hash")
        IO.inspect(password, label: "Provided Password")

        if Bcrypt.verify_pass(password, hash) do
          {:ok, token, _claims} = JWT.generate_token(user)
          json(conn, %{token: token})
        else
          IO.puts("Password verification failed")
          unauthorized_response(conn)
        end

      _ ->
        IO.puts("User not found")
        unauthorized_response(conn)
    end
  end

  # def login(conn, %{"username" => username, "password" => password}) do
  #   case Repo.get_by(User, username: username) do
  #     %User{password_hash: hash} = user ->
  #       if Argon2.verify_pass(password, hash) do
  #         {:ok, token, _claims} = JWT.generate_token(user)
  #         json(conn, %{token: token})
  #       else
  #         unauthorized_response(conn)
  #       end

  #     _ ->
  #       unauthorized_response(conn)
  #   end
  # end

  defp unauthorized_response(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Invalid username or password"})
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
