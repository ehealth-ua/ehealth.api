defmodule GraphQLWeb.Resolvers.MedicalProgramResolver do
  @moduledoc false

  import GraphQL.Helpers.Filtering, only: [filter: 2]
  import Ecto.Query, only: [order_by: 2]

  alias Absinthe.Relay.Connection
  alias Core.MedicalPrograms.MedicalProgram

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_medical_programs(%{filter: filter, order_by: order_by} = args, _) do
    MedicalProgram
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end
end
