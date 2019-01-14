defmodule Core.ILFactories.DeclarationRequestFactory do
  @moduledoc false

  alias Core.DeclarationRequests.DeclarationRequest
  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def declaration_request_factory do
        uuid = UUID.generate()

        data =
          "../core/test/data/sign_declaration_request.json"
          |> File.read!()
          |> Jason.decode!()

        %DeclarationRequest{
          data: put_in(data, ~w(person authentication_methods), [%{"type" => "OFFLINE"}]),
          status: "NEW",
          inserted_by: uuid,
          updated_by: uuid,
          authentication_method_current: %{
            type: "NA",
            number: "+38093*****85"
          },
          printout_content: "something",
          documents: [],
          channel: DeclarationRequest.channel(:mis),
          declaration_number: to_string(:os.system_time()) <> to_string(Enum.random(1..1000)),
          declaration_id: UUID.generate(),
          data_legal_entity_id: get_in(data, ~w(legal_entity id)),
          data_employee_id: get_in(data, ~w(employee id)),
          data_start_date_year: data |> Map.get("start_date") |> Date.from_iso8601!() |> Map.get(:year),
          data_person_tax_id: get_in(data, ~w(person tax_id)),
          data_person_first_name: get_in(data, ~w(person first_name)),
          data_person_last_name: get_in(data, ~w(person last_name)),
          data_person_birth_date: data |> get_in(~w(person birth_date)) |> Date.from_iso8601!()
        }
      end
    end
  end
end
