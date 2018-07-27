defmodule EHealth.ILFactories.DeclarationRequestFactory do
  @moduledoc false

  alias EHealth.DeclarationRequests.DeclarationRequest
  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def declaration_request_factory do
        uuid = UUID.generate()

        data =
          "test/data/sign_declaration_request.json"
          |> File.read!()
          |> Jason.decode!()

        %DeclarationRequest{
          data: data,
          status: "NEW",
          inserted_by: uuid,
          updated_by: uuid,
          authentication_method_current: %{
            type: "NA",
            number: "+38093*****85"
          },
          printout_content: "something",
          documents: [],
          channel: DeclarationRequest.channel(:mis),
          declaration_number: to_string(DateTime.to_unix(DateTime.utc_now())) <> to_string(Enum.random(1..1000)),
          declaration_id: UUID.generate()
        }
      end
    end
  end
end
