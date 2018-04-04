defmodule EHealth.Cabinet.API.DeclarationsAPI do
  @moduledoc false

  import EHealth.Utils.TypesConverter, only: [strings_to_keys: 1]

  alias EHealth.Persons
  alias EHealth.Employees

  @ops_api Application.get_env(:ehealth, :api_resolvers)[:ops]

  def get_declarations(%{} = params, headers) do
    with {:ok, person} <- Persons.get_person(headers),
         declaration_params <- Map.merge(params, %{"person_id" => person["id"]}),
         {:ok, %{"data" => declarations, "paging" => paging}} <- @ops_api.get_declarations(declaration_params, headers),
         employees <- preload_employees(declarations),
         paging <- strings_to_keys(paging) do
      {:ok, %{declarations: declarations, employees: employees, person: person, paging: paging}}
    end
  end

  defp preload_employees(declarations) when is_list(declarations) do
    declarations
    |> Enum.map(&Map.get(&1, "employee_id"))
    |> Employees.get_preloaded_by_ids()
    |> Map.new(&{&1.id, &1})
  end
end
