defmodule QserveIspApi.Mpesa do
  alias QserveIspApi.Repo
  alias QserveIspApi.Mpesa.Credential
  import Ecto.Query
  import Ecto.Query, only: [from: 2]


  @static_config Application.compile_env(:qserve_isp_api, :mpesa)

  def fetch_credentials(user_id) do
    Repo.get_by(Credential, user_id: user_id)
  end

  def list_credentials_for_user(user_id) do
    from(c in Credential, where: c.user_id == ^user_id)
    |> Repo.all()
  end



  def add_shortcode(attrs) do
    %Credential{}
    |> Credential.changeset(attrs)
    |> Repo.insert()
  end


  def ensure_only_one_active(user_id) do
    query =
      from c in Credential,
        where: c.user_id == ^user_id and c.status == true

    Repo.update_all(query, set: [status: false])
  end


  def add_or_update_credentials(attrs) do
    Repo.transaction(fn ->
      existing_credential =
        from(c in Credential,
          where: c.user_id == ^attrs["user_id"] and c.shortcode_type == ^attrs["shortcode_type"]
        )
        |> Repo.one()

      if existing_credential do
        # Update the existing credential
        changeset = Credential.changeset(existing_credential, attrs)

        case Repo.update(changeset) do
          {:ok, updated_credential} ->
            {:ok, updated_credential}

          {:error, changeset} ->
            Repo.rollback({:error, changeset})
        end
      else
        # Insert new credential
        changeset = Credential.changeset(%Credential{}, attrs)

        case Repo.insert(changeset) do
          {:ok, new_credential} ->
            {:ok, new_credential}

          {:error, changeset} ->
            Repo.rollback({:error, changeset})
        end
      end
    end)
  end

  def set_active_credential(id, user_id) do
    Repo.transaction(fn ->
      # Set all other credentials for this user to `false`
      from(c in Credential,
        where: c.user_id == ^user_id and c.id != ^id,
        update: [set: [status: false]]
      )
      |> Repo.update_all([])

      # Set the specified credential to `true`
      credential =
        Credential
        |> Repo.get!(id)
        |> Credential.changeset(%{status: true})
        |> Repo.update()

      case credential do
        {:ok, updated_credential} -> updated_credential
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  # def add_or_update_credentials(attrs) do
  #   Repo.transaction(fn ->
  #     existing_credential =
  #       from(c in QserveIspApi.Mpesa.Credential,
  #         where: c.shortcode_type == ^attrs["shortcode_type"] and c.user_id == ^attrs["user_id"]
  #       )
  #       |> Repo.one()

  #     if existing_credential do
  #       # Update existing credential
  #       changeset = QserveIspApi.Mpesa.Credential.changeset(existing_credential, attrs)

  #       case Repo.update(changeset) do
  #         {:ok, updated_credential} ->
  #           {:ok, updated_credential}

  #         {:error, changeset} ->
  #           Repo.rollback({:error, changeset})
  #       end
  #     else
  #       # Insert new credential
  #       changeset = QserveIspApi.Mpesa.Credential.changeset(%QserveIspApi.Mpesa.Credential{}, attrs)

  #       case Repo.insert(changeset) do
  #         {:ok, new_credential} ->
  #           {:ok, new_credential}

  #         {:error, changeset} ->
  #           Repo.rollback({:error, changeset})
  #       end
  #     end
  #   end)
  # end


  # def add_or_update_credentials(attrs) do
  #   Repo.transaction(fn ->
  #     # Check if a credential with the given shortcode type exists for the user
  #     existing_credential =
  #       from(c in QserveIspApi.Mpesa.Credential,
  #         where: c.shortcode_type == ^attrs["shortcode_type"] and c.user_id == ^attrs["user_id"]
  #       )
  #       |> Repo.one()

  #     if existing_credential do
  #       # Update the existing credential
  #       changeset = QserveIspApi.Mpesa.Credential.changeset(existing_credential, attrs)

  #       case Repo.update(changeset) do
  #         {:ok, updated_credential} ->
  #           {:ok, updated_credential}

  #         {:error, changeset} ->
  #           {:error, changeset}
  #       end
  #     else
  #       # Insert a new credential
  #       changeset = QserveIspApi.Mpesa.Credential.changeset(%QserveIspApi.Mpesa.Credential{}, attrs)

  #       case Repo.insert(changeset) do
  #         {:ok, new_credential} ->
  #           {:ok, new_credential}

  #         {:error, changeset} ->
  #           {:error, changeset}
  #       end
  #     end
  #   end)
  # end

  # def add_or_update_credentials(attrs) do
  #   user_id = attrs["user_id"]

  #   Repo.transaction(fn ->
  #     # Deactivate any active credentials for this user
  #     ensure_only_one_active(user_id)

  #     # Add or update the credential
  #     query = from c in Credential, where: c.user_id == ^user_id and c.short_code == ^attrs["short_code"]

  #     case Repo.one(query) do
  #       nil ->
  #         %Credential{}
  #         |> Credential.changeset(attrs)
  #         |> Repo.insert()

  #       credential ->
  #         credential
  #         |> Credential.changeset(attrs)
  #         |> Repo.update()
  #     end
  #   end)
  # end

  # def add_or_update_credentials(attrs) do
  #   Repo.transaction(fn ->
  #     case Repo.get_by(Credential, user_id: attrs["user_id"]) do
  #       nil ->
  #         %Credential{}
  #         |> Credential.changeset(attrs)
  #         |> Repo.insert()

  #       credential ->
  #         credential
  #         |> Credential.changeset(attrs)
  #         |> Repo.update()
  #     end
  #   end)
  # end

  # def add_or_update_credentials(attrs) do
  #   user_id = attrs["user_id"]

  #   Repo.transaction(fn ->
  #     if attrs["status"] do
  #       Repo.update_all(
  #         from(c in Credential, where: c.user_id == ^user_id),
  #         set: [status: false]
  #       )
  #     end

  #     %Credential{}
  #     |> Credential.changeset(attrs)
  #     |> Repo.insert_or_update()
  #   end)
  # end

  def get_active_shortcode(user_id) do
    Repo.one(
      from c in Credential,
        where: c.user_id == ^user_id and c.status == true
    )
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Ecto.Changeset.apply_action(msg, opts)
    end)
  end


  def static_config, do: @static_config
end
