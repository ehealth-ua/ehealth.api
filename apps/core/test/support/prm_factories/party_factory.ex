defmodule Core.PRMFactories.PartyFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def party_factory do
        %Core.Parties.Party{
          first_name: "Петро",
          last_name: last_name(),
          second_name: "Миколайович",
          birth_date: ~D[1991-08-19],
          gender: "MALE",
          tax_id: random_tax_id(),
          no_tax_id: false,
          documents: [
            %Core.Parties.Document{
              type: "NATIONAL_ID",
              number: "AA000000"
            }
          ],
          phones: [
            %Core.Parties.Phone{
              type: "MOBILE",
              number: "+380972526080"
            }
          ],
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          declaration_limit: 10
        }
      end

      def party_user_factory(attrs) do
        record = %Core.PartyUsers.PartyUser{
          user_id: UUID.generate(),
          party: build(:party)
        }

        record
        |> drop_overridden_fields(attrs)
        |> merge_attributes(attrs)
      end

      def random_tax_id, do: sequence(:tax_id, &(100_000_000 + &1)) |> to_string()

      defp last_name do
        Enum.random(~w(
            Антоновіч
            Аркас
            Білокур
            Беринда
            Вавілов
            Вернадський
            В'язовська
            Гамалія
            Драгоманов
            Корш
            Куліш
            Крушельницька
            Либідь
            Пулюй
            Сікорський
            Стефанишин
            Чубиньский
            Яворський
          ))
      end
    end
  end
end
