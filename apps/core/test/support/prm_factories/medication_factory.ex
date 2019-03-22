defmodule Core.PRMFactories.MedicationFactory do
  @moduledoc false

  alias Core.Medications.INNM
  alias Core.Medications.Program, as: ProgramMedication
  alias Core.Medications.INNMDosage
  alias Core.Medications.INNMDosage.Ingredient, as: INNMDosageIngredient
  alias Core.Medications.Medication
  alias Core.Medications.Medication.Ingredient, as: MedicationIngredient

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def program_medication_factory do
        medication_id = insert(:prm, :medication).id
        innm_dosage_id = insert(:prm, :innm_dosage).id
        insert(:prm, :ingredient_medication, parent_id: medication_id, medication_child_id: innm_dosage_id)

        %ProgramMedication{
          reimbursement: build(:reimbursement),
          medication_request_allowed: true,
          is_active: true,
          wholesale_price: random_price(1, 50),
          consumer_price: random_price(51, 200),
          reimbursement_daily_dosage: random_price(1, 3),
          estimated_payment_amount: random_price(1, 50),
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
          medication_id: medication_id,
          medical_program_id: insert(:prm, :medical_program).id
        }
      end

      def innm_factory do
        %INNM{
          sctid: sequence("1234567"),
          name: "Преднизолон",
          name_original: sequence("Prednisolonum"),
          is_active: true,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate()
        }
      end

      def innm_dosage_factory do
        %INNMDosage{
          name: sequence("Prednisolonum Forte"),
          type: INNMDosage.type(),
          form: "PILL",
          is_active: true,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate()
        }
      end

      def medication_factory do
        %Medication{
          name: sequence("Prednisolonum Forte"),
          type: Medication.type(),
          form: "TABLET",
          container: container("PILL"),
          manufacturer: build(:manufacturer),
          package_qty: 30,
          package_min_qty: 10,
          certificate: to_string(3_300_000_000 + :rand.uniform(99_999_999)),
          certificate_expired_at: ~D[2012-04-17],
          is_active: true,
          code_atc: [sequence("C08CA0")],
          daily_dosage: 0.5,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate()
        }
      end

      def ingredient_innm_dosage_factory do
        %INNMDosageIngredient{
          id: UUID.generate(),
          innm_child_id: UUID.generate(),
          parent_id: UUID.generate(),
          is_primary: true,
          dosage: %{
            numerator_unit: "MG",
            numerator_value: 5,
            denumerator_unit: "PILL",
            denumerator_value: 1
          }
        }
      end

      def ingredient_medication_factory do
        %MedicationIngredient{
          id: UUID.generate(),
          medication_child_id: UUID.generate(),
          parent_id: UUID.generate(),
          is_primary: true,
          dosage: %{
            numerator_unit: "MG",
            numerator_value: 5,
            denumerator_unit: "PILL",
            denumerator_value: 1
          }
        }
      end

      def manufacturer_factory do
        %{
          name: "ПАТ `Київський вітамінний завод`",
          country: "UA"
        }
      end

      def reimbursement_factory do
        %{
          type: "FIXED",
          reimbursement_amount: 10
        }
      end

      def container("PILL") do
        %{
          numerator_unit: "PILL",
          numerator_value: 1,
          denumerator_unit: "PILL",
          denumerator_value: 1
        }
      end

      def container("Nebuliser suspension") do
        %{
          numerator_unit: "ML",
          numerator_value: 2,
          denumerator_unit: "CONTAINER",
          denumerator_value: 1
        }
      end

      defp random_price(from, to), do: Enum.random(from..to) * 1.0
    end
  end
end
