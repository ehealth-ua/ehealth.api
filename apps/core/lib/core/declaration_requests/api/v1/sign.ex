defmodule Core.DeclarationRequests.API.Sign do
  @moduledoc false

  import Core.API.Helpers.Connection
  import Ecto.Changeset

  alias Core.API.MediaStorage
  alias Core.DeclarationRequests
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.DeclarationRequests.SignRequest
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.Repo
  alias Core.ValidationError
  alias Core.Validators.Content, as: ContentValidator
  alias Core.Validators.Error
  alias Core.Validators.Signature, as: SignatureValidator
  alias HTTPoison.Response

  require Logger

  @mpi_api Application.get_env(:core, :api_resolvers)[:mpi]
  @ops_api Application.get_env(:core, :api_resolvers)[:ops]
  @casher_api Application.get_env(:core, :api_resolvers)[:casher]

  @auth_na DeclarationRequest.authentication_method(:na)
  @auth_otp DeclarationRequest.authentication_method(:otp)
  @auth_offline DeclarationRequest.authentication_method(:offline)

  @status_approved DeclarationRequest.status(:approved)

  def sign(params, headers) do
    with {:ok, %{"content" => content, "signers" => [signer]}} <- decode_and_validate(params, headers),
         %DeclarationRequest{} = declaration_request <- params |> Map.fetch!("id") |> DeclarationRequests.get_by_id!(),
         :ok <- check_status(declaration_request),
         :ok <- check_patient_signed(content),
         :ok <- compare_with_db(content, declaration_request, headers),
         :ok <- check_employee_id(content, headers),
         :ok <- SignatureValidator.check_drfo(signer, get_consumer_id(headers), "declaration_request_sign"),
         :ok <- store_signed_content(declaration_request, params, headers),
         {:ok, person} <- create_or_update_person(declaration_request, content, headers),
         {:ok, declaration} <- create_declaration_with_termination_logic(person, declaration_request, headers),
         :ok <- update_casher_person_data(declaration["data"]["employee_id"]),
         {:ok, signed_declaration} <- update_declaration_request_status(declaration_request, declaration) do
      {:ok, signed_declaration}
    end
  end

  def decode_and_validate(params, headers) do
    params
    |> validate_sign_request()
    |> validate_signature(headers)
  end

  def validate_sign_request(params) do
    fields = ~W(
      signed_declaration_request
      signed_content_encoding
    )a

    %SignRequest{}
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_inclusion(:signed_content_encoding, ["base64"])
  end

  def validate_signature(%Ecto.Changeset{valid?: true, changes: changes}, headers) do
    with {:ok, %{"content" => content, "signers" => [signer]}} <-
           SignatureValidator.validate(
             Map.get(changes, :signed_declaration_request),
             Map.get(changes, :signed_content_encoding),
             headers
           ) do
      {:ok, %{"content" => content, "signers" => [signer]}}
    else
      error -> normalize_signature_error(error)
    end
  end

  def validate_signature(err, _headers), do: err

  def normalize_signature_error({:error, %{"meta" => %{"description" => error}}}) do
    %SignRequest{}
    |> cast(%{}, [:signed_declaration_request])
    |> add_error(:signed_declaration_request, error)
  end

  def normalize_signature_error({:error, %{"error" => %{"message" => message}, "meta" => %{"code" => code}}}) do
    %SignRequest{}
    |> cast(%{}, [:signed_declaration_request])
    |> add_error(:signed_declaration_request, "#{code}: #{message}")
  end

  def normalize_signature_error(ok_resp), do: ok_resp

  def check_status(%DeclarationRequest{status: status}) do
    case status do
      @status_approved -> :ok
      _ -> Error.dump(%ValidationError{description: "incorrect status", path: "$.status"})
    end
  end

  def check_patient_signed(""),
    do: Error.dump(%ValidationError{description: "Can not be empty", path: "$.declaration_request"})

  def check_patient_signed(content) do
    case get_in(content, ["person", "patient_signed"]) do
      true ->
        :ok

      _ ->
        Error.dump(%ValidationError{description: "Patient must sign declaration form", path: "$.person.patient_signed"})
    end
  end

  def compare_with_db(content, %DeclarationRequest{} = declaration_request, headers \\ []) do
    db_content =
      declaration_request
      |> Map.get(:data)
      |> put_in(["person", "patient_signed"], true)
      |> Map.put("id", Map.get(declaration_request, :id))
      |> Map.put("status", Map.get(declaration_request, :status))
      |> Map.put("content", Map.get(declaration_request, :printout_content))
      |> Map.put("declaration_number", Map.get(declaration_request, :declaration_number))
      |> Map.put("seed", current_hash(headers))

    ContentValidator.compare_with_db(content, db_content, "declaration_request_sign")
  end

  def check_employee_id(content, headers) do
    employee_id = get_in(content, ["employee", "id"])

    with %Employee{legal_entity_id: legal_entity_id, status: status} <- Employees.get_by_id(employee_id),
         true <- legal_entity_id == get_client_id(headers),
         true <- status == Employee.status(:approved) do
      :ok
    else
      _ -> {:error, :forbidden}
    end
  end

  def store_signed_content(%DeclarationRequest{} = declaration_request, input, headers) do
    input
    |> Map.fetch!("signed_declaration_request")
    |> MediaStorage.store_signed_content(
      :declaration_bucket,
      Map.fetch!(declaration_request, :declaration_id),
      "signed_content",
      headers
    )
    |> case do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def create_or_update_person(%DeclarationRequest{} = declaration_request, content, headers) do
    content
    |> Map.fetch!("person")
    |> Map.put("patient_signed", true)
    |> maybe_put("id", declaration_request.mpi_id)
    |> @mpi_api.create_or_update_person(headers)
    |> create_or_update_person_response()
  end

  defp create_or_update_person_response({:ok, %Response{status_code: 409}}), do: {:conflict, "person is not active"}

  defp create_or_update_person_response({:ok, %Response{status_code: 404}}), do: {:conflict, "person is not found"}

  defp create_or_update_person_response({:ok, %Response{body: person, status_code: code}}) when code in [200, 201] do
    Jason.decode(person)
  end

  defp create_or_update_person_response({:ok, %Response{status_code: 422, body: errors}}) do
    {:error, :person_changeset, errors}
  end

  defp create_or_update_person_response(error), do: error

  def create_declaration_with_termination_logic(
        %{"data" => %{"id" => person_id}} = person,
        %DeclarationRequest{
          id: id,
          data: data,
          authentication_method_current: authentication_method_current,
          declaration_id: declaration_id,
          declaration_number: declaration_number,
          overlimit: overlimit
        },
        headers
      ) do
    consumer_id = get_consumer_id(headers)
    person_no_tax_id = get_in(person, ~w(data no_tax_id)) || false
    person_authentication_method = List.first(get_in(data, ~w(person authentication_methods)) || [])

    data
    |> Map.take(["start_date", "end_date", "scope", "seed"])
    |> Map.merge(%{
      "id" => declaration_id,
      "employee_id" => get_in(data, ["employee", "id"]),
      "division_id" => get_in(data, ["division", "id"]),
      "legal_entity_id" => get_in(data, ["legal_entity", "id"]),
      "person_id" => person_id,
      "status" => get_status(authentication_method_current, person_no_tax_id),
      "is_active" => true,
      "created_by" => consumer_id,
      "updated_by" => consumer_id,
      "signed_at" => Timex.now(),
      "declaration_request_id" => id,
      "overlimit" => overlimit,
      "declaration_number" => declaration_number,
      "reason" => get_reason(authentication_method_current, person_no_tax_id, person_authentication_method)
    })
    |> @ops_api.create_declaration_with_termination_logic(headers)
  end

  defp get_reason(_, true, _), do: "no_tax_id"
  defp get_reason(%{"type" => @auth_offline}, _, _), do: "offline"
  defp get_reason(%{"type" => @auth_na}, _, person_auth), do: get_reason(person_auth, nil, %{})
  defp get_reason(_, _, _), do: nil

  defp update_casher_person_data(employee_id) do
    with {:ok, _response} <- @casher_api.update_person_data(%{"employee_id" => employee_id}, []) do
      :ok
    end
  rescue
    error ->
      Logger.warn("Failed to save cache #{inspect(error)}")
      :ok
  end

  def update_declaration_request_status(%DeclarationRequest{} = declaration_request, declaration) do
    declaration_request =
      declaration_request
      |> DeclarationRequests.changeset(%{status: "SIGNED"})
      |> Repo.update()

    declaration_data =
      declaration
      |> Map.get("data")
      |> Map.drop(["updated_by", "updated_at", "created_by"])

    case declaration_request do
      {:ok, _data} -> {:ok, declaration_data}
      err -> err
    end
  end

  defp get_status(%{"type" => @auth_offline}, _), do: "pending_verification"
  defp get_status(%{"type" => @auth_otp}, false), do: "active"
  defp get_status(%{"type" => @auth_otp}, _), do: "pending_verification"
  defp get_status(%{"type" => @auth_na}, false), do: "active"
  defp get_status(%{"type" => @auth_na}, _), do: "pending_verification"

  defp get_status(_, _) do
    Logger.error("Unknown authentication_method_current.type")
    ""
  end

  defp current_hash(headers) do
    {:ok, %{"data" => %{"hash" => hash}}} = @ops_api.get_latest_block(headers)
    hash
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
