defmodule GraphQLWeb.Resolvers.ContractRequestResolver do
  @moduledoc false

  import Absinthe.Resolution.Helpers, only: [on_load: 2]
  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]

  alias Core.ContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.Renderer
  alias Core.Dictionaries.Dictionary
  alias Core.LegalEntities.LegalEntity
  alias Core.Man.Templates.ContractRequestPrintoutForm
  alias GraphQLWeb.Loaders.{IL, PRM}

  @status_in_process CapitationContractRequest.status(:in_process)
  @status_pending_nhs_sign CapitationContractRequest.status(:pending_nhs_sign)
  @status_signed CapitationContractRequest.status(:signed)

  @review_text_dictionary "CONTRACT_REQUEST_REVIEW_TEXT"

  def get_printout_content(%CapitationContractRequest{status: @status_pending_nhs_sign} = contract_request, _, %{
        context: context
      }) do
    contract_request = Map.put(contract_request, :nhs_signed_date, Date.utc_today())

    # todo: causes N+1 problem with DB query and man template rendering
    with {:ok, printout_content} <- ContractRequestPrintoutForm.render(contract_request, context.headers) do
      {:ok, printout_content}
    else
      err -> render_error(err)
    end
  end

  def get_printout_content(%CapitationContractRequest{printout_content: printout_content}, _, _),
    do: {:ok, printout_content}

  def get_attached_documents(%{id: id, status: status}, _, _) do
    with documents when is_list(documents) <- ContractRequests.gen_relevant_get_links(id, status) do
      {:ok, documents}
    end
  end

  def get_to_approve_content(%{status: @status_in_process} = contract_request, _, %{context: %{loader: loader}}) do
    get_to_review_content("APPROVED", contract_request, loader)
  end

  def get_to_approve_content(_, _, _), do: {:ok, nil}

  def get_to_decline_content(%{status: @status_signed}, _, _), do: {:ok, nil}

  def get_to_decline_content(contract_request, _, %{context: %{loader: loader}}) do
    get_to_review_content("DECLINED", contract_request, loader)
  end

  defp get_to_review_content(next_status, contract_request, loader) do
    %{contractor_legal_entity_id: contractor_legal_entity_id} = contract_request

    loader
    |> Dataloader.load(PRM, LegalEntity, contractor_legal_entity_id)
    |> Dataloader.load(IL, {:one, Dictionary}, name: @review_text_dictionary)
    |> on_load(fn loader ->
      with %LegalEntity{} = legal_entity <- Dataloader.get(loader, PRM, LegalEntity, contractor_legal_entity_id),
           %Dictionary{values: values} <- Dataloader.get(loader, IL, {:one, Dictionary}, name: @review_text_dictionary),
           {:ok, text} <- Map.fetch(values, next_status) do
        to_review_content =
          Renderer.render_review_content(contract_request, %{
            contractor_legal_entity: legal_entity,
            text: text,
            next_status: next_status
          })

        {:ok, to_review_content}
      end
    end)
  end

  def get_to_sign_content(%{status: @status_pending_nhs_sign} = contract_request, args, resolution) do
    # ToDo: possible duplicated request to MediaStorage. Use dataloader
    with {:ok, printout_content} <- get_printout_content(contract_request, args, resolution) do
      to_sign_content =
        contract_request
        |> Renderer.render(ContractRequests.preload_references(contract_request))
        |> Map.put(:printout_content, printout_content)

      {:ok, to_sign_content}
    end
  end

  def get_to_sign_content(_, _, _), do: {:ok, nil}

  def update(args, resolution) do
    params = prepare_update_params(args)

    with {:ok, contract_request, references} <- ContractRequests.update(resolution.context.headers, params) do
      {:ok, %{contract_request: Map.merge(contract_request, references)}}
    else
      err -> render_error(err)
    end
  end

  defp prepare_update_params(args) do
    for {key, value} <- args, into: %{} do
      case key do
        :miscellaneous -> {"misc", value}
        key -> {to_string(key), value}
      end
    end
  end

  def approve(args, resolution) do
    params = prepare_signed_content_params(args)

    with {:ok, contract_request, references} <- ContractRequests.approve(resolution.context.headers, params) do
      {:ok, %{contract_request: Map.merge(contract_request, references)}}
    else
      err -> render_error(err)
    end
  end

  def sign(args, %{context: %{headers: headers}}) do
    params = prepare_signed_content_params(args)

    with {:ok, contract_request, _references} <- ContractRequests.sign_nhs(headers, params) do
      {:ok, %{contract_request: contract_request}}
    else
      err -> render_error(err)
    end
  end

  def decline(args, resolution) do
    params = prepare_signed_content_params(args)

    with {:ok, contract_request, references} <- ContractRequests.decline(resolution.context.headers, params) do
      {:ok, %{contract_request: Map.merge(contract_request, references)}}
    else
      err -> render_error(err)
    end
  end

  defp prepare_signed_content_params(%{signed_content: signed_content, id: id}) do
    %{
      "id" => id,
      "signed_content" => signed_content.content,
      "signed_content_encoding" => to_string(signed_content.encoding)
    }
  end

  def update_assignee(%{id: id, employee_id: employee_id}, %{context: %{headers: headers}}) do
    with {:ok, contract_request, _} <-
           ContractRequests.update_assignee(headers, %{"id" => id, "employee_id" => employee_id}) do
      {:ok, %{contract_request: contract_request}}
    else
      err -> render_error(err)
    end
  end
end
