defmodule Core.V2.LegalEntities.Licenses do
  @moduledoc false

  alias Core.LegalEntities.LegalEntityCreator
  alias Core.LegalEntities.License
  alias Core.PRMRepo
  alias Core.ValidationError
  alias Core.Validators.Error
  alias Ecto.Changeset
  import Ecto.Changeset
  import Ecto.Query

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def get_license(license_id) do
    License
    |> where([l], l.id == ^license_id)
    |> preload(:edr_data)
    |> @read_prm_repo.one()
  end

  def check_license(%LegalEntityCreator{} = state, nil, nil, _, _, _), do: state
  def check_license(_, nil, _, _, _, _), do: {:error, {:conflict, "License is needed for chosen legal entity type"}}

  def check_license(_, params, nil, _, _, _) when params != %{} do
    {:error, {:conflict, "License is not needed for chosen legal entity type"}}
  end

  def check_license(%LegalEntityCreator{} = state, params, required_license, edr_data_id, consumer_id, license_id) do
    cond do
      Map.has_key?(params, "id") && Map.keys(params) != ~w(id) ->
        params
        |> Map.drop(~w(id))
        |> Enum.map(fn {k, _} ->
          %ValidationError{
            description: "schema does not allow additional properties",
            path: "$.license.#{k}"
          }
        end)
        |> Error.dump()

      Map.has_key?(params, "id") ->
        with %License{} = license <- get_license(license_id),
             {_, true} <- {:required_license, license.type == required_license},
             {_, true} <- {:edr_data, license_correspond_to_legal_entity?(edr_data_id, license)},
             {_, true} <-
               {:expiry_date, license.expiry_date && Date.compare(license.expiry_date, Date.utc_today()) != :lt} do
          state
        else
          nil ->
            Error.dump(%ValidationError{
              description: "License not found",
              path: "$.license.id"
            })

          {:required_license, _} ->
            {:error, {:conflict, "Legal entity type and license type mismatch"}}

          {:edr_data, _} ->
            {:error, {:conflict, "License doesn't correspond to your legal entity"}}

          {:expiry_date, _} ->
            {:error, {:conflict, "License is expired"}}
        end

      true ->
        license_data =
          Map.merge(params, %{
            "id" => license_id,
            "is_active" => true,
            "inserted_by" => consumer_id,
            "updated_by" => consumer_id
          })

        with {license, type} <- get_or_create_license(license_id),
             %Changeset{valid?: true} = changeset <- License.changeset(license, license_data),
             {_, true} <- {:required_license, apply_changes(changeset).type == required_license},
             expiry_date <- apply_changes(changeset).expiry_date,
             {_, true} <-
               {:expiry_date, expiry_date && Date.compare(expiry_date, Date.utc_today()) != :lt} do
          case type do
            :insert ->
              %{state | inserts: [fn -> PRMRepo.insert_and_log(changeset, consumer_id) end | state.inserts]}

            :update ->
              %{state | updates: [fn -> PRMRepo.update_and_log(changeset, consumer_id) end | state.updates]}
          end
        else
          {:required_license, _} ->
            {:error, {:conflict, "Legal entity type and license type mismatch"}}

          {:expiry_date, _} ->
            {:error, {:conflict, "License is expired"}}

          error ->
            error
        end
    end
  end

  defp get_or_create_license(id) do
    case get_license(id) do
      %License{} = license -> {license, :update}
      _ -> {%License{}, :insert}
    end
  end

  defp license_correspond_to_legal_entity?(edr_data_id, %License{edr_data: edr_data}) do
    !is_nil(Enum.find(edr_data, &(Map.get(&1, :id) == edr_data_id)))
  end
end
