defmodule Core.ILFactories.ContractRequestFactory do
  @moduledoc false

  alias Ecto.UUID
  alias Core.ContractRequests.CapitationContractRequest

  defmacro __using__(_opts) do
    quote do
      def capitation_contract_request_factory do
        legal_entity = insert(:prm, :legal_entity)
        employee = insert(:prm, :employee)

        division =
          insert(
            :prm,
            :division,
            legal_entity: legal_entity,
            phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
          )

        today = Date.utc_today()
        end_date = Date.add(today, 50)

        data =
          Map.merge(generic_contract_request_data(legal_entity, division), %{
            contract_type: CapitationContractRequest.type(),
            nhs_contract_price: 50_000.00,
            external_contractor_flag: true,
            contractor_rmsp_amount: 10,
            external_contractors: [
              %{
                "legal_entity_id" => legal_entity.id,
                "divisions" => [%{"id" => division.id, "medical_service" => "PHC_SERVICES"}],
                "contract" => %{
                  "number" => "1234567",
                  "issued_at" => to_string(today),
                  "expires_at" => to_string(end_date)
                }
              }
            ],
            contractor_employee_divisions: [
              %{
                "employee_id" => employee.id,
                "staff_units" => 0.5,
                "declaration_limit" => 2000,
                "division_id" => division.id
              }
            ]
          })

        struct(CapitationContractRequest, data)
      end

      def generic_contract_request_data(legal_entity, division) do
        today = Date.utc_today()
        end_date = Date.add(today, 50)

        %{
          id: UUID.generate(),
          contractor_owner_id: UUID.generate(),
          contractor_base: "на підставі закону про Медичне обслуговування населення",
          contractor_payment_details: %{
            "bank_name" => "Банк номер 1",
            "MFO" => "351005",
            "payer_account" => "32009102701026"
          },
          contractor_legal_entity_id: legal_entity.id,
          data: %{},
          id_form: "5",
          contractor_divisions: [division.id],
          status: CapitationContractRequest.status(:new),
          start_date: today,
          end_date: end_date,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          issue_city: "Київ",
          nhs_signer_id: UUID.generate(),
          nhs_signer_base: "на підставі наказу",
          nhs_payment_method: "FORWARD",
          nhs_legal_entity_id: UUID.generate()
        }
      end
    end
  end
end
