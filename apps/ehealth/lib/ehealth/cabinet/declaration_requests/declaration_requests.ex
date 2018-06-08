defmodule EHealth.Cabinet.DeclarationRequests do
  @moduledoc false

  import Ecto.Query
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.Repo
  alias EHealth.Cabinet.DeclarationRequestsSearch
  alias EHealth.DeclarationRequests.DeclarationRequest
  alias Scrivener.Page

  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]
  @mpi_api Application.get_env(:ehealth, :api_resolvers)[:mpi]

  def search(search_params, headers) do
    user_id = get_consumer_id(headers)

    with {:ok, %{"data" => user}} <- @mithril_api.get_user_by_id(user_id, headers),
         {:ok, %{"data" => person}} <- @mpi_api.person(user["person_id"], headers),
         :ok <- validate_user_person(user, person),
         :ok <- check_user_blocked(user["is_blocked"]),
         %Ecto.Changeset{valid?: true} <- DeclarationRequestsSearch.changeset(search_params),
         %Page{} = paging <- get_person_declaration_requests(search_params, user_id) do
      {:ok, paging}
    end
  end

  defp validate_user_person(user, person) do
    if user["person_id"] == person["id"] and user["tax_id"] == person["tax_id"] do
      :ok
    else
      {:error, {:access_denied, "Person not found"}}
    end
  end

  defp check_user_blocked(false), do: :ok

  defp check_user_blocked(true), do: {:error, :access_denied}

  def get_person_declaration_requests(params, user_id) do
    DeclarationRequest
    |> order_by([dr], desc: :inserted_at)
    |> filter_by_person_id(user_id)
    |> filter_by_status(params)
    |> filter_by_start_year(params)
    |> Repo.paginate(params)
  end

  defp filter_by_person_id(query, user_id) when is_binary(user_id) do
    where(query, [r], r.mpi_id == ^user_id)
  end

  defp filter_by_person_id(query, _), do: query

  defp filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end

  defp filter_by_status(query, _), do: query

  defp filter_by_start_year(query, %{"start_year" => start_year}) when is_binary(start_year) do
    where(query, [r], fragment("date_part_immutable(?) = to_number(?, '9999')", r.data, ^start_year))
  end

  defp filter_by_start_year(query, _), do: query
end
