defmodule Core.PRMFactories.ContractFactory do
  @moduledoc false

  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ContractDivision
  alias Core.Contracts.ContractEmployee
  alias Core.Contracts.ReimbursementContract
  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def capitation_contract_factory do
        data =
          Map.merge(generic_contract_data(), %{
            type: CapitationContract.type(),
            nhs_contract_price: to_float(Enum.random(100_000..200_000)),
            contractor_rmsp_amount: Enum.random(50_000..100_000),
            external_contractor_flag: true,
            external_contractors: [
              %{
                legal_entity_id: UUID.generate(),
                contract: %{
                  number: "1234567",
                  issued_at: NaiveDateTime.utc_now(),
                  expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(), days_to_seconds(365), :second)
                },
                divisions: [
                  %{
                    id: UUID.generate(),
                    name: "Бориспільське відділення Клініки Ноунейм",
                    medical_service: "Послуга ПМД"
                  }
                ]
              }
            ]
          })

        struct(%CapitationContract{}, data)
      end

      def reimbursement_contract_factory do
        %{id: medical_program_id} = insert(:prm, :medical_program)

        data =
          Map.merge(generic_contract_data(), %{
            type: ReimbursementContract.type(),
            medical_program_id: medical_program_id
          })

        struct(%ReimbursementContract{}, data)
      end

      def generic_contract_data do
        %{
          id: UUID.generate(),
          start_date: Date.utc_today(),
          end_date: Date.utc_today(),
          status: CapitationContract.status(:verified),
          contractor_legal_entity: build(:legal_entity),
          contractor_owner: build(:employee),
          contractor_base: "на підставі закону про Медичне обслуговування населення",
          contractor_payment_details: %{
            bank_name: "Банк номер 1",
            MFO: "351005",
            payer_account: "32009102701026"
          },
          nhs_legal_entity: build(:legal_entity),
          nhs_signer: build(:employee),
          nhs_payment_method: "prepayment",
          nhs_signer_base: "на підставі наказу",
          issue_city: "Київ",
          contract_number: "0000-9EAX-XT7X-3115",
          contract_request_id: UUID.generate(),
          is_active: true,
          is_suspended: false,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          parent_contract: nil,
          id_form: to_string(Enum.random(1..20)),
          nhs_signed_date: Date.utc_today()
        }
      end

      def contract_employee_factory do
        %ContractEmployee{
          contract_id: UUID.generate(),
          employee_id: UUID.generate(),
          division_id: UUID.generate(),
          staff_units: to_float(Enum.random(100_000..200_000)),
          declaration_limit: 2000,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          start_date: NaiveDateTime.utc_now()
        }
      end

      def contract_division_factory do
        %ContractDivision{
          contract_id: UUID.generate(),
          division_id: UUID.generate(),
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end

      defp days_to_seconds(days_count), do: days_count * 24 * 60 * 60
      defp to_float(number) when is_integer(number), do: number + 0.0
    end
  end
end
