defmodule QserveIspApi.Nas do

  import Ecto.Query, warn: false
  alias QserveIspApi.Repo
  alias QserveIspApi.Nas.Nas


  @doc """
  Returns the list of NAS.
  """
  def list_nas do
    Repo.all(Nas)
  end

  @doc """
  Gets a single NAS by ID.
  """
  def get_nas!(id), do: Repo.get!(Nas, id)

    @doc """
  Returns the list of NAS entries for a specific user.
  """
  # def list_user_nas(user_id) do
  #   from(n in Nas, where: n.user_id == ^user_id)
  #   |> Repo.all()
  # end
  def list_user_nas(user_id) do
    QserveIspApi.Repo.all(
      from n in Nas,
        where: n.user_id == ^user_id
    )
    |> Enum.map(&add_status/1)
  end

  # Helper function to add the status
  # defp add_status(nas) do
  #   status =
  #     case :gen_tcp.connect(String.to_charlist(nas.nasname), 22, [:binary, active: false, timeout: 1000]) do
  #       {:ok, _socket} ->
  #         :online
  #       {:error, _reason} ->
  #         :offline
  #     end

  #   Map.put(nas, :status, status)
  # end

  defp add_status(nas) do
    status =
      case System.cmd("ping", ["-c", "1", nas.nasname]) do
        {_, 0} -> "online"
        _ -> "offline"
      end

    Map.put(nas, :status, status)
  end

  # defp add_status2(nas) do
  #   case System.cmd("ping", ["-c", "1", nas.nasname]) do
  #     {_, 0} -> :online
  #     _ -> :offline
  #   end
  # end

  @doc """
  Gets a single NAS entry for a specific user.
  """
  def get_user_nas(user_id, id) do
    from(n in Nas, where: n.user_id == ^user_id and n.id == ^id)
    |> Repo.one()
  end

  @doc """
  Creates a new NAS entry.
  """
  def create_nas(attrs \\ %{}) do
    %Nas{}
    |> Nas.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing NAS entry.
  """
  def update_nas(%Nas{} = nas, attrs) do
    nas
    |> Nas.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a NAS entry.
  """
  def delete_nas(%Nas{} = nas) do
    Repo.delete(nas)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking NAS changes.
  """
  def change_nas(%Nas{} = nas, attrs \\ %{}) do
    Nas.changeset(nas, attrs)
  end
end
