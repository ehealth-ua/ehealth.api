defmodule Core.LegalEntities.RelatedLegalEntities do
  @moduledoc false

  import Ecto.Query
  alias Core.LegalEntities.RelatedLegalEntity
  alias Core.PRMRepo

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list(%{"id" => id} = params, id) do
    RelatedLegalEntity
    |> where([rle], rle.merged_to_id == ^id)
    |> join(:left, [rle], from_le in assoc(rle, :merged_from))
    |> preload([rle, from_le], merged_from: from_le)
    |> @read_prm_repo.paginate(Map.delete(params, "id"))
  end

  def list(_, _) do
    {:error, {:forbidden, "User is not allowed to view"}}
  end

  def get_related_by(args), do: @read_prm_repo.get_by(RelatedLegalEntity, args)

  def create(%RelatedLegalEntity{} = related_legal_entity, attrs, author_id) do
    related_legal_entity
    |> RelatedLegalEntity.changeset(attrs)
    |> PRMRepo.insert_and_log(author_id)
  end
end
