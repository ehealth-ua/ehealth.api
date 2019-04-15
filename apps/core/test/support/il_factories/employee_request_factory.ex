defmodule Core.ILFactories.EmployeeRequestFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID
      alias Core.EmployeeRequests.EmployeeRequest, as: Request

      def employee_request_factory do
        %Request{
          data: employee_request_data(),
          employee_id: UUID.generate(),
          status: "NEW"
        }
      end

      def employee_request_data do
        %{
          division_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          legal_entity_id: "8b797c23-ba47-45f2-bc0f-521013e01074",
          position: "лікар",
          start_date: "2017-08-07",
          status: "NEW",
          employee_type: "DOCTOR",
          party: %{
            first_name: "Петро",
            last_name: "Іванов",
            second_name: "Миколайович",
            birth_date: "1991-08-19",
            gender: "MALE",
            tax_id: "3067305998",
            no_tax_id: false,
            email: "sp.virny@gmail.com",
            documents: [
              %{
                type: "PASSPORT",
                number: "120518",
                issued_at: "2019-04-08",
                issued_by: "Нептун"
              }
            ],
            phones: [
              %{
                type: "MOBILE",
                number: "+380503410870"
              }
            ]
          },
          doctor: %{
            educations: [
              %{
                country: "UA",
                city: "Київ",
                institution_name: "Академія Богомольця",
                issued_date: "2017-08-01",
                diploma_number: "DD123543",
                degree: "Молодший спеціаліст",
                speciality: "Педіатр"
              }
            ],
            qualifications: [
              %{
                type: "Інтернатура",
                institution_name: "Академія Богомольця",
                speciality: "Педіатр",
                issued_date: "2017-08-02",
                certificate_number: "2017-08-03",
                valid_to: "2017-10-10",
                additional_info: "additional info"
              }
            ],
            specialities: [
              %{
                speciality: "Педіатр",
                speciality_officio: true,
                level: "Перша категорія",
                qualification_type: "Присвоєння",
                attestation_name: "Академія Богомольця",
                attestation_date: "2017-08-04",
                valid_to_date: "2017-08-05",
                certificate_number: "AB/21331"
              }
            ],
            science_degree: %{
              country: "UA",
              city: "Київ",
              degree: "Доктор філософії",
              institution_name: "Академія Богомольця",
              diploma_number: "DD123543",
              speciality: "Педіатр",
              issued_date: "2017-08-05"
            }
          }
        }
      end
    end
  end
end
