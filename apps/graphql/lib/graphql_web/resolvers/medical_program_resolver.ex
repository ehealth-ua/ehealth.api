defmodule GraphQLWeb.Resolvers.MedicalProgramResolver do
  @moduledoc false

  import GraphQL.Helpers.Filtering, only: [filter: 2]
  import Ecto.Query, only: [order_by: 2]

  alias Absinthe.Relay.Connection
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.PRMRepo

  def list_medical_programs(%{filter: filter, order_by: order_by} = args, _) do
    MedicalProgram
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&PRMRepo.all/1, args)
  end
end
