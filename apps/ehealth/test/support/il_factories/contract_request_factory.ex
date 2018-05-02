defmodule EHealth.ILFactories.ContractRequestFactory do
  @moduledoc false

  alias Ecto.UUID
  alias EHealth.ContractRequests.ContractRequest

  defmacro __using__(_opts) do
    quote do
      def contract_request_factory do
        legal_entity = insert(:prm, :legal_entity)
        employee = insert(:prm, :employee)
        division = insert(:prm, :division, legal_entity: legal_entity)
        today = Date.utc_today()
        end_date = Date.add(today, 50)

        %ContractRequest{
          id: UUID.generate(),
          contractor_owner_id: UUID.generate(),
          contractor_base: "на підставі закону про Медичне обслуговування населення",
          contractor_payment_details: %{
            "bank_name" => "Банк номер 1",
            "MFO" => "351005",
            "payer_account" => "32009102701026"
          },
          contractor_legal_entity_id: legal_entity.id,
          contractor_rmsp_amount: 10,
          id_form: "5",
          contractor_employee_divisions: [
            %{
              "employee_id" => employee.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ],
          external_contractors: [
            %{
              "divisions" => [%{"id" => division.id}],
              "contract" => %{"expires_at" => to_string(end_date)}
            }
          ],
          status: ContractRequest.status(:new),
          external_contractor_flag: true,
          start_date: today,
          end_date: end_date,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          issue_city: "Київ",
          nhs_signer_base: "на підставі наказу",
          nhs_contract_price: 50_000.00,
          nhs_payment_method: "prepayment"
        }
      end
    end
  end
end
