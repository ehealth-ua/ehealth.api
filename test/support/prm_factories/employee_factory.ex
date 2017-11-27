defmodule EHealth.PRMFactories.EmployeeFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def employee_factory do
        division = build(:division)
        party = build(:party)

        %EHealth.Employees.Employee{
          is_active: true,
          position: "some position",
          status: "APPROVED",
          employee_type: "DOCTOR",
          end_date: ~D[2012-04-17],
          start_date: ~D[2017-08-07],
          party: party,
          division: division,
          legal_entity_id: division.legal_entity.id,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          additional_info: doctor(),
        }
      end

      def doctor do
        %{
          "science_degree" => %{
            "country" => "UA",
            "city" => "Kyiv",
            "degree" => Enum.random(doctor_science_degrees()),
            "institution_name" => "random string",
            "diploma_number" => "random string",
            "speciality" => "random string",
            "issued_date" => ~D[1987-04-17],
          },
          "qualifications" => [
            %{
              "type" => Enum.random(doctor_types()),
              "institution_name" => "random string",
              "speciality" => Enum.random(doctor_specialities()),
              "certificate_number" => "random string",
              "issued_date" => ~D[1987-04-17],
            }
          ],
          "educations" => [
            %{
              "country" => "UA",
              "city" => "Kyiv",
              "degree" => Enum.random(doctor_degrees()),
              "institution_name" => "random string",
              "diploma_number" => "random string",
              "speciality" => "random string",
              "issued_date" => ~D[1987-04-17],
            }
          ],
          "specialities" => [
            %{
              "speciality" => Enum.random(doctor_specialities()),
              "speciality_officio" => true,
              "level" => Enum.random(doctor_levels()),
              "qualification_type" => Enum.random(doctor_qualification_types()),
              "attestation_name" => "random string",
              "attestation_date" => ~D[1987-04-17],
              "valid_to_date" => ~D[1987-04-17],
              "certificate_number" => "random string",
            }
          ]
        }
      end

      defp doctor_degrees do
        [
          "Молодший спеціаліст",
          "Бакалавр",
          "Спеціаліст",
          "Магістр"
        ]
      end

      defp doctor_science_degrees do
        [
          "Доктор філософії",
          "Кандидат наук",
          "Доктор наук"
        ]
      end

      defp doctor_specialities do
        [
          "Терапевт",
          "Педіатр",
          "Сімейний лікар",
        ]
      end

      defp doctor_levels do
        [
          "Друга категорія",
          "Перша категорія",
          "Вища категорія"
        ]
      end

      defp doctor_qualification_types do
        [
          "Присвоєння",
          "Підтвердження"
        ]
      end

      defp doctor_types do
        [
          "Інтернатура",
          "Спеціалізація",
          "Передатестаційний цикл",
          "Тематичне вдосконалення",
          "Курси інформації",
          "Стажування",
        ]
      end
    end
  end
end
