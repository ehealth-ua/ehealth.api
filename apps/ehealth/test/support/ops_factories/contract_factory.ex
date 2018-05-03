defmodule EHealth.OPSFactories.ContractFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def contract_factory do
        contractor_legal_entity = insert(:prm, :legal_entity)
        nhs_legal_entity = insert(:prm, :legal_entity)
        contractor_owner = insert(:prm, :employee)
        nhs_signer = insert(:prm, :employee)

        %{
          id: UUID.generate(),
          start_date: NaiveDateTime.utc_now(),
          end_date: NaiveDateTime.add(NaiveDateTime.utc_now(), days_to_seconds(30), :seconds),
          status: "VERIFIED",
          contractor_legal_entity_id: contractor_legal_entity.id,
          contractor_owner_id: contractor_owner.id,
          contractor_base: "на підставі закону про Медичне обслуговування населення",
          contractor_payment_details: %{
            bank_name: "Банк номер 1",
            MFO: "351005",
            payer_account: "32009102701026"
          },
          contractor_rmsp_amount: Enum.random(50_000..100_000),
          external_contractor_flag: true,
          external_contractors: [
            %{
              legal_entity: %{
                id: UUID.generate(),
                name: "Клініка Ноунейм"
              },
              contract: %{
                number: "1234567",
                issued_at: NaiveDateTime.utc_now(),
                expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(), days_to_seconds(365), :seconds)
              },
              divisions: [
                %{
                  id: UUID.generate(),
                  name: "Бориспільське відділення Клініки Ноунейм",
                  medical_service: "Послуга ПМД"
                }
              ]
            }
          ],
          nhs_legal_entity_id: nhs_legal_entity.id,
          nhs_signer_id: nhs_signer.id,
          nhs_payment_method: "prepayment",
          nhs_payment_details: %{
            bank_name: "Банк номер 1",
            MFO: "351005",
            payer_account: "32009102701026"
          },
          nhs_signer_base: "на підставі наказу",
          issue_city: "Київ",
          price: Enum.random(100_000..200_000),
          contract_number: "0000-9EAX-XT7X-3115",
          contract_request_id: UUID.generate(),
          is_active: true,
          is_suspended: false,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end

      defp days_to_seconds(days_count), do: days_count * 24 * 60 * 60
    end
  end
end
