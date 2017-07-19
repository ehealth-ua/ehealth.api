defmodule EHealth.DeclarationRequest.API.Create do
  @moduledoc false

  alias EHealth.API.MediaStorage
  alias EHealth.API.MPI
  alias EHealth.API.Gandalf
  alias EHealth.Man.Templates.DeclarationRequestPrintoutForm
  alias EHealth.API.OTPVerification
  alias Ecto.Changeset

  import Ecto.Changeset, only: [get_field: 2, put_change: 3, add_error: 3]

  use Confex, otp_app: :ehealth

  @files_storage_bucket Confex.get_map(:ehealth, EHealth.API.MediaStorage)[:declaration_request_bucket]

  def send_verification_code(number) do
    OTPVerification.initialize(number)
  end

  def generate_upload_urls(id, document_list) do
    link_versions =
      for verb <- ["PUT"],
          document_type <- document_list, do: {verb, document_type}

    documents =
      Enum.reduce_while link_versions, [], fn {verb, document_type}, acc ->
        result =
          MediaStorage.create_signed_url(verb, @files_storage_bucket, "declaration_request_#{document_type}.jpeg", id)

        case result do
          {:ok, %{"data" => %{"secret_url" => url}}} ->
            url_details = %{
              "type" => document_type,
              "verb" => verb,
              "url" => url
            }

            {:cont, [url_details|acc]}
          {:error, error_response} ->
            {:halt, {:error, error_response}}
        end
      end

    case documents do
      {:error, error_response} ->
        {:error, format_error_response("MediaStorage", error_response)}
      _ ->
        {:ok, documents}
    end
  end

  def generate_printout_form(%Changeset{valid?: false} = changeset), do: changeset
  def generate_printout_form(changeset) do
    form_data = %{
      id: get_field(changeset, :id)
    }

    case DeclarationRequestPrintoutForm.render(form_data) do
      {:ok, printout_content} ->
        put_change(changeset, :printout_content, printout_content)
      {:error, error_response} ->
        add_error(changeset, :printout_content, format_error_response("MAN", error_response))
    end
  end

  def determine_auth_method_for_mpi(%Changeset{valid?: false} = changeset), do: changeset
  def determine_auth_method_for_mpi(changeset) do
    data = get_field(changeset, :data)

    result = MPI.search(%{
      "first_name"   => data["person"]["first_name"],
      "second_name"  => data["person"]["second_name"],
      "last_name"    => data["person"]["last_name"],
      "birth_date"   => data["person"]["birth_date"],
      "tax_id"       => data["person"]["tax_id"]
    })

    case result do
      {:ok, %{"data" => [person|_]}} ->
        {:ok, %{"data" => person_details}} = MPI.person(person["id"])

        [authentication_method|_] = person_details["authentication_methods"]

        authentication_method_current = %{
          "type" => authentication_method["type"],
          "number" => authentication_method["phone_number"]
        }

        put_change(changeset, :authentication_method_current, authentication_method_current)
      {:ok, %{"data" => []}} ->
        [authentication_method|_] = data["person"]["authentication_methods"]

        gandalf_decision = Gandalf.decide_auth_method(
          not is_nil(authentication_method["phone_number"]),
          authentication_method["type"]
        )

        case gandalf_decision do
          {:ok, %{"data" => decision}} ->
            authentication_method_current = %{
              "type" => decision["final_decision"],
              "number" => authentication_method["phone_number"]
            }

            put_change(changeset, :authentication_method_current, authentication_method_current)
          {:error, error_response} ->
            add_error(changeset, :authentication_method_current, format_error_response("Gandalf", error_response))
          _other ->
            require Logger
            Logger.info("Gandalf is not responding. Falling back to default...")

            authentication_method_current = %{
              "type" => "OFFLINE",
              "number" => authentication_method["phone_number"]
            }

            put_change(changeset, :authentication_method_current, authentication_method_current)
        end
      {:error, error_response} ->
        add_error(changeset, :authentication_method_current, format_error_response("MPI", error_response))
    end
  end

  def prepare_legal_entity_struct(legal_entity) do
    legal_entity_attrs = [
      "id",
      "name",
      "short_name",
      "phones",
      "legal_form",
      "edrpou",
      "public_name",
      "email",
      "addresses"
    ]

    msp_attrs = [
      "accreditation",
      "licenses"
    ]

    additional_attrs =
      legal_entity
      |> Map.get("medical_service_provider", msp_attrs)
      |> Map.take(msp_attrs)

    legal_entity
    |> Map.drop(["medical_service_provider"])
    |> Map.take(legal_entity_attrs)
    |> Map.merge(additional_attrs)
  end

  def prepare_employee_struct(employee) do
    employee_attrs = [
      "id",
      "party",
      "position"
    ]

    Map.take(employee, employee_attrs)
  end

  def prepare_division_struct(division) do
    division_attrs = [
      "id",
      "type",
      "phones",
      "name",
      "legal_entity_id",
      "external_id",
      "email",
      "addresses"
    ]

    Map.take(division, division_attrs)
  end

  defp format_error_response(microservice, result) do
    "Error during #{microservice} interaction. Result from #{microservice}: #{inspect result}"
  end
end
