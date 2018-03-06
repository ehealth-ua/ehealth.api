defmodule EHealth.Persons do
  @moduledoc false

  alias EHealth.API.MPI
  alias EHealth.API.Mithril
  alias EHealth.API.Signature
  alias EHealth.Persons.Person
  alias EHealth.Persons.Search
  alias EHealth.Persons.Signed
  alias EHealth.Parties
  alias EHealth.Validators.JsonSchema
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  def search(params, headers \\ []) do
    with %Ecto.Changeset{valid?: true, changes: changes} <- Search.changeset(params),
         search_params <- Map.put(changes, "status", "active"),
         {:ok, %{"data" => persons, "paging" => %{"total_pages" => 1}}} <- MPI.search(search_params, headers) do
      {:ok, persons, changes}
    else
      {:ok, %{"paging" => %{"total_pages" => _}} = paging} -> {:error, paging}
      error -> error
    end
  end

  def update(id, params, headers) do
    user_id = get_consumer_id(headers)

    with {:ok, %{"data" => user}} <- Mithril.get_user_by_id(user_id, headers),
         :ok <- check_user_mpi_id(user, id),
         %Ecto.Changeset{valid?: true, changes: changes} <- Signed.changeset(params),
         {:ok, %{"data" => %{"content" => content, "signer" => signer}}} <-
           Signature.decode_and_validate(changes.signed_content, "base64", headers),
         tax_id when not is_nil(tax_id) <- Parties.get_tax_id_by_user_id(user_id),
         :ok <- validate_tax_id(tax_id, content, signer),
         :ok <- JsonSchema.validate(:person, content),
         %Ecto.Changeset{valid?: true, changes: changes} <- Person.changeset(content),
         {:ok, %{"data" => data}} <- MPI.update_person(id, changes, headers) do
      {:ok, data}
    end
  end

  defp check_user_mpi_id(user, id) do
    if user["person_id"] == id do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp validate_tax_id(tax_id, content, signer) do
    with true <- tax_id == content["tax_id"],
         true <- content["tax_id"] == signer["edrpou"] do
      :ok
    else
      _ ->
        {:error, {:conflict, "Person that logged in, person that is changed and person that sign should be the same"}}
    end
  end
end
