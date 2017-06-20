defmodule EHealth.DeclarationRequest.API.Create do
  @moduledoc false

  alias EHealth.API.MediaStorage
  alias EHealth.API.MPI
  alias EHealth.API.Gandalf
  alias EHealth.Man.Templates.DeclarationRequestPrintoutForm

  import Ecto.Changeset, only: [get_field: 2, put_change: 3, add_error: 3]

  use Confex, otp_app: :ehealth

  @files_storage_bucket Confex.get_map(:ehealth, EHealth.API.MediaStorage)[:declaration_request_bucket]

  def send_verification_code(_multi) do
    {:ok, "Verification code was sent!"}
  end

  def generate_upload_urls(changeset) do
    id = get_field(changeset, :id)

    documents =
      Enum.map config()[:declaration_request_offline_documents], fn document_type ->
        result =
          MediaStorage.create_signed_url("PUT", @files_storage_bucket, "declaration_request_#{document_type}.jpeg", id)

        case result do
          {:ok, %{"data" => %{"upload_link" => url}}} ->
            %{"type" => document_type, "url" => url}
          _ ->
            {:error, document_type}
        end
      end

    failed_calls = Enum.filter(documents, &is_tuple(&1))

    if length(failed_calls) > 0 do
      failed_document_types =
        failed_calls
        |> Enum.map(&(elem(&1, 1)))
        |> Enum.join(", ")

      message = "Error when generating uploading URLs for #{failed_document_types}. Please, retry."

      add_error(changeset, :documents, message)
    else
      put_change(changeset, :documents, documents)
    end
  end

  def generate_printout_form(changeset) do
    form_data = %{
      id: get_field(changeset, :id)
    }

    printout_content = DeclarationRequestPrintoutForm.render(form_data)

    # TODO: add proper error handling!
    put_change(changeset, :printout_content, printout_content)
  end

  def determine_auth_method_for_mpi(changeset) do
    data = get_field(changeset, :data)

    [%{"number" => phone_number}|_] = data["person"]["phones"]

    result = MPI.search(%{
      "first_name"   => data["person"]["first_name"],
      "last_name"    => data["person"]["last_name"],
      "birth_date"   => "#{data["person"]["birth_date"]} 00:00:00",
      "tax_id"       => data["person"]["tax_id"],
      "phone_number" => phone_number
    })

    case result do
      {:ok, %{"data" => [person|_]}} ->
        {:ok, %{"data" => person_details}} = MPI.person(person["id"])

        [authentication_method|_] = person_details["authentication_methods"]

        authentication_method_current = %{
          "type" => authentication_method["type"],
          "number" => authentication_method["number"]
        }

        put_change(changeset, :authentication_method_current, authentication_method_current)
      {:ok, %{"data" => []}} ->
        [authentication_method|_] = data["person"]["authentication_methods"]

        gandalf_decision = Gandalf.decide_auth_method(
          not is_nil(authentication_method["number"]),
          authentication_method["type"]
        )

        case gandalf_decision do
          {:ok, %{"data" => decision}} ->
            authentication_method_current = %{
              "type" => decision["final_decision"],
              "number" => authentication_method["number"]
            }

            put_change(changeset, :authentication_method_current, authentication_method_current)
          _ ->
            add_error(changeset, :authentication_method_current, format_error_response("Gandalf", gandalf_decision))
        end
      _ ->
        add_error(changeset, :authentication_method_current, format_error_response("MPI", result))
    end
  end

  defp format_error_response(microservice, result) do
    "Error during #{microservice} interaction. Result from #{microservice}: #{inspect result}"
  end
end
