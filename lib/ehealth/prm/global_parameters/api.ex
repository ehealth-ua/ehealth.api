defmodule EHealth.PRM.GlobalParameters do
  @moduledoc """
  The boundary for the Global parameters system.
  """

  import Ecto.Query

  alias EHealth.PRMRepo
  alias EHealth.PRM.GlobalParameters.Schema, as: GlobalParameter

  def list_global_parameters do
    query = from gp in GlobalParameter,
      order_by: [desc: :inserted_at]

    PRMRepo.all(query)
  end
end
