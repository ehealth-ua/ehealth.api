defmodule EHealth.PRMFactories.PartyFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def party_factory do
        %EHealth.Parties.Party{
          first_name: "Петро",
          last_name: "Іванов",
          second_name: "Миколайович",
          birth_date: ~D[1991-08-19],
          gender: "MALE",
          tax_id: sequence("222222222"),
          no_tax_id: false,
          documents: [
            %EHealth.Parties.Document{
              type: "NATIONAL_ID",
              number: "AA000000"
            }
          ],
          phones: [
            %EHealth.Parties.Phone{
              type: "MOBILE",
              number: "+380972526080"
            }
          ],
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end

      def party_user_factory do
        %EHealth.PartyUsers.PartyUser{
          user_id: UUID.generate(),
          party: build(:party)
        }
      end
    end
  end
end
