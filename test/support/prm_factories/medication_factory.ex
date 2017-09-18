defmodule EHealth.PRMFactories.MedicationFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def substance_factory do
        %EHealth.PRM.Medication.Substance{
          sctid: sequence("1234567"),
          name: "Преднизолон",
          name_original: "Prednisolonum",
          is_active: true,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
        }
      end

      def innm_factory do
        form = Enum.random(["Pill", "Nebuliser suspension"])

        %EHealth.PRM.Medication{
          name: sequence("Prednisolonum Forte"),
          type: "INNM",
          form: form,
          ingredients: [build(:ingredient)],
          container: %{},
          manufacturer: %{},
          package_min_qty: nil,
          package_qty: nil,
          code_atc: nil,
          certificate: nil,
          certificate_expired_at: nil,
          is_active: true,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
        }
      end

      def medication_factory do
        form = Enum.random(["Pill", "Nebuliser suspension"])

        %EHealth.PRM.Medication{
          name: sequence("Prednisolonum Forte"),
          type: "MEDICATION",
          form: form,
          ingredients: [build(:ingredient)],
          container: container(form),
          manufacturer: build(:manufacturer),
          package_qty: 10,
          package_min_qty: 30,
          certificate: to_string(3_300_000_000 + :rand.uniform(99_999_999)),
          certificate_expired_at: ~D[2012-04-17],
          is_active: true,
          code_atc: sequence("C08CA0"),
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
        }
      end

      def ingredient_factory do
        %{
          "id" => UUID.generate(),
          "is_active_substance" => true,
          "dosage" => %{
            "numerator_unit" => "mg",
            "numerator_value" => 5,
            "denumerator_unit" => "g",
            "denumerator_value" => 1
          }
        }
      end

      def manufacturer_factory do
        %{
          "name" => "ПАТ `Київський вітамінний завод`",
          "country" => "Україна"
        }
      end

      def container("Pill") do
        %{
          "numerator_unit" => "pill",
          "numerator_value" => 1,
          "denumerator_unit" => "pill",
          "denumerator_value" => 1
        }
      end

      def container("Nebuliser suspension") do
        %{
          "numerator_unit" => "ml",
          "numerator_value" => 2,
          "denumerator_unit" => "container",
          "denumerator_value" => 1
        }
      end
    end
  end
end
