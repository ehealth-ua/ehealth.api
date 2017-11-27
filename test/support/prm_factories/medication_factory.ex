defmodule EHealth.PRMFactories.MedicationFactory do
  @moduledoc false

  alias EHealth.Medications.INNM
  alias EHealth.Medications.Program, as: ProgramMedication
  alias EHealth.Medications.INNMDosage
  alias EHealth.Medications.INNMDosage.Ingredient, as: INNMDosageIngredient
  alias EHealth.Medications.Medication
  alias EHealth.Medications.Medication.Ingredient, as: MedicationIngredient

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def program_medication_factory do
        med_id = insert(:prm, :medication, type: "INNM_DOSAGE").id
        insert(:prm, :ingredient_medication, [parent_id: med_id, medication_child_id: med_id])

        %ProgramMedication{
          reimbursement: build(:reimbursement),
          medication_request_allowed: true,
          is_active: true,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
          medication_id: med_id,
          medical_program_id: insert(:prm, :medical_program).id,
        }
      end

      def innm_factory do
        %INNM{
          sctid: sequence("1234567"),
          name: sequence("Преднизолон"),
          name_original: sequence("Prednisolonum"),
          is_active: true,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
        }
      end

      def innm_dosage_factory do
        %INNMDosage{
          name: sequence("Prednisolonum Forte"),
          type: INNMDosage.type(),
          form: "Pill",
          is_active: true,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
        }
      end

      def medication_factory do
        form = "Pill"

        %Medication{
          name: sequence("Prednisolonum Forte"),
          type: Medication.type(),
          form: form,
          container: container(form),
          manufacturer: build(:manufacturer),
          package_qty: 30,
          package_min_qty: 10,
          certificate: to_string(3_300_000_000 + :rand.uniform(99_999_999)),
          certificate_expired_at: ~D[2012-04-17],
          is_active: true,
          code_atc: sequence("C08CA0"),
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
        }
      end

      def ingredient_innm_dosage_factory do
        %INNMDosageIngredient{
          id: UUID.generate(),
          innm_child_id: UUID.generate(),
          parent_id: UUID.generate(),
          is_primary: true,
          dosage: %{
            numerator_unit: "mg",
            numerator_value: 5,
            denumerator_unit: "pill",
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
            numerator_unit: "mg",
            numerator_value: 5,
            denumerator_unit: "pill",
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

      def container("Pill") do
        %{
          numerator_unit: "pill",
          numerator_value: 1,
          denumerator_unit: "pill",
          denumerator_value: 1
        }
      end

      def container("Nebuliser suspension") do
        %{
          numerator_unit: "ml",
          numerator_value: 2,
          denumerator_unit: "container",
          denumerator_value: 1
        }
      end
    end
  end
end
