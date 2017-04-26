defmodule EHealth.LegalEntity.API do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

  alias EHealth.LegalEntity.Validator

  def create_legal_entity(attrs) do
    attrs
    |> Validator.validate()
  end

end
