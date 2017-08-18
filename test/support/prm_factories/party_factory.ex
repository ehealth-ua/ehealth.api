defmodule EHealth.PRMFactories.PartyFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def party_factory do
        %EHealth.PRM.Parties.Schema{
          birth_date: ~D[1987-04-17],
          documents: [
            %EHealth.PRM.Meta.Document{
              type: "NATIONAL_ID",
              number: "AA000000"
            }
          ],
          first_name: "some first_name",
          gender: "some gender",
          last_name: "some last_name",
          phones: [
            %EHealth.PRM.Meta.Phone{
              type: "MOBILE",
              number: "+380972526080"
            }
          ],
          second_name: "some second_name",
          tax_id: "some tax_id",
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end

      def party_user_factory do
        %EHealth.PRM.PartyUsers.Schema{
          user_id: UUID.generate(),
          party: build(:party),
        }
      end
    end
  end
end
