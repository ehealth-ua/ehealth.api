defmodule GraphQLWeb.Resolvers.ContractRequestResolver do
  @moduledoc false

  import Absinthe.Resolution.Helpers, only: [on_load: 2]
  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]

  alias Core.ContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.ContractRequests.Renderer
  alias Core.ContractRequests.RequestPack
  alias Core.Dictionaries.Dictionary
  alias Core.LegalEntities.LegalEntity
  alias Core.Man.Templates.ContractRequestPrintoutForm
  alias GraphQLWeb.Loaders.{IL, PRM}

  @status_in_process CapitationContractRequest.status(:in_process)
  @status_pending_nhs_sign CapitationContractRequest.status(:pending_nhs_sign)
  @status_signed CapitationContractRequest.status(:signed)

  @review_text_dictionary "CONTRACT_REQUEST_REVIEW_TEXT"

  defmacro __using__(opts) do
    quote do
      import Ecto.Query, only: [where: 3, select: 3, order_by: 2]

      alias Absinthe.Relay.Connection
      alias Core.{PRMRepo, Repo}
      alias GraphQL.Helpers.Filtering

      @schema unquote(opts[:schema])
      @related_schemas @schema.related_schemas()

      def list_contract_requests(args, %{context: %{client_type: "NHS"}}), do: list_contract_requests(args)

      def list_contract_requests(args, %{
            context: %{client_type: unquote(opts[:restricted_client_type]), client_id: client_id}
          }) do
        args
        |> Map.update!(:filter, &[{:contractor_legal_entity_id, :equal, client_id} | &1])
        |> list_contract_requests()
      end

      defp list_contract_requests(%{filter: filter, order_by: order_by} = args) do
        @schema
        |> where([c], c.type == ^@schema.type())
        |> filter(filter)
        |> order_by(^order_by)
        |> Connection.from_query(&Repo.all/1, args)
      end

      defp filter(query, []), do: query

      defp filter(query, [{field, nil, conditions} | tail]) when field in @related_schemas do
        ids =
          field
          |> @schema.related_schema()
          |> Filtering.filter(conditions)
          |> select([r], r.id)
          |> PRMRepo.all()

        filter(query, [{:"#{field}_id", :in, ids} | tail])
      end

      # BUG: When association condition goes before regular conditions,
      # all following conditions will be applied to the associated table
      defp filter(query, [condition | tail]) do
        query
        |> Filtering.filter([condition])
        |> filter(tail)
      end
    end
  end

  def get_printout_content(%ReimbursementContractRequest{printout_content: printout_content}, _, _) do
    # TODO: Rewrite logic when reimbursement contract request form is ready
    {:ok, printout_content}
  end

  def get_printout_content(%{status: @status_pending_nhs_sign} = contract_request, _, %{context: context}) do
    contract_request = Map.put(contract_request, :nhs_signed_date, Date.utc_today())

    # TODO: causes N+1 problem with DB query and man template rendering
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
    else
      err -> render_error(err)
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
    else
      err -> render_error(err)
    end
  end

  def get_to_sign_content(_, _, _), do: {:ok, nil}

  def update(args, resolution) do
    params = Enum.reduce(args, %{}, &prepare_update_param/2)

    with {:ok, contract_request, references} <- ContractRequests.update(resolution.context.headers, params) do
      {:ok, %{contract_request: Map.merge(contract_request, references)}}
    else
      err -> render_error(err)
    end
  end

  def update_assignee(args, %{context: %{headers: headers}}) do
    params = Enum.reduce(args, %{}, &prepare_update_param/2)

    with {:ok, contract_request, _} <- ContractRequests.update_assignee(params, headers) do
      {:ok, %{contract_request: contract_request}}
    else
      err -> render_error(err)
    end
  end

  def approve(args, %{context: %{headers: headers}}) do
    params = prepare_signed_content_params(args)

    with {:ok, contract_request, references} <- ContractRequests.approve(params, headers) do
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

  def decline(args, %{context: %{headers: headers}}) do
    params = prepare_signed_content_params(args)

    with {:ok, contract_request, references} <- ContractRequests.decline(params, headers) do
      {:ok, %{contract_request: Map.merge(contract_request, references)}}
    else
      err -> render_error(err)
    end
  end

  defp prepare_update_param({:id, %{id: id, type: type}}, acc),
    do: Map.merge(acc, %{"id" => id, "type" => RequestPack.get_type_by_atom(type)})

  defp prepare_update_param({:miscellaneous, value}, acc), do: Map.put(acc, "misc", value)
  defp prepare_update_param({key, value}, acc), do: Map.put(acc, to_string(key), value)

  defp prepare_signed_content_params(%{signed_content: signed_content, id: %{id: id, type: type}}) do
    %{
      "id" => id,
      "type" => RequestPack.get_type_by_atom(type),
      "signed_content" => signed_content.content,
      "signed_content_encoding" => to_string(signed_content.encoding)
    }
  end
end
