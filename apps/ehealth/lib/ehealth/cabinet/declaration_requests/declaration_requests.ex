defmodule EHealth.Cabinet.DeclarationRequests do
  @moduledoc false

  import Ecto.Query
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.Cabinet.DeclarationRequestsSearch
  alias EHealth.DeclarationRequests.DeclarationRequest
  alias EHealth.Repo
  alias Scrivener.Page

  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]
  @mpi_api Application.get_env(:ehealth, :api_resolvers)[:mpi]
  @status_expired DeclarationRequest.status(:expired)

  def search(search_params, headers) do
    user_id = get_consumer_id(headers)

    with {:ok, %{"data" => user}} <- @mithril_api.get_user_by_id(user_id, headers),
         {:ok, %{"data" => person}} <- @mpi_api.person(user["person_id"], headers),
         :ok <- validate_user_person(user, person),
         :ok <- check_user_blocked(user["is_blocked"]),
         %Ecto.Changeset{valid?: true} <- DeclarationRequestsSearch.changeset(search_params),
         %Page{} = paging <- get_person_declaration_requests(search_params, person["id"]) do
      {:ok, paging}
    end
  end

  def get_by_id(id, headers) do
    user_id = get_consumer_id(headers)

    with {:ok, %{"data" => user}} <- @mithril_api.get_user_by_id(user_id, headers),
         {:ok, %{"data" => person}} <- @mpi_api.person(user["person_id"], headers),
         :ok <- validate_user_person(user, person),
         :ok <- check_user_blocked(user["is_blocked"]),
         %DeclarationRequest{} = declaration_request <- Repo.get(DeclarationRequest, id),
         :ok <- validate_person_id(declaration_request, person["id"]) do
      {:ok, declaration_request}
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

  defp get_person_declaration_requests(%{"status" => @status_expired} = params, _) do
    %Page{
      entries: [],
      page_number: 1,
      page_size: Map.get(params, "page_size", 50),
      total_entries: 0,
      total_pages: 1
    }
  end

  defp get_person_declaration_requests(params, person_id) do
    DeclarationRequest
    |> order_by([dr], desc: :inserted_at)
    |> filter_by_person_id(person_id)
    |> filter_by_status(params)
    |> filter_by_start_year(params)
    |> Repo.paginate(params)
  end

  defp filter_by_person_id(query, person_id) when is_binary(person_id) do
    where(query, [r], r.mpi_id == ^person_id)
  end

  defp filter_by_person_id(query, _), do: query

  defp filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end

  defp filter_by_status(query, _) do
    where(query, [r], r.status != ^@status_expired)
  end

  defp filter_by_start_year(query, %{"start_year" => start_year}) when is_binary(start_year) do
    where(query, [r], fragment("date_part_immutable(?) = to_number(?, '9999')", r.data, ^start_year))
  end

  defp filter_by_start_year(query, _), do: query

  defp validate_person_id(%DeclarationRequest{mpi_id: person_id}, person_id), do: :ok
  defp validate_person_id(_, _), do: {:error, :forbidden}
end
