defmodule EHealth.DeclarationRequest.API.Create do
  @moduledoc false

  alias EHealth.API.AEL
  alias EHealth.API.MPI
  alias EHealth.API.Gandalf
  alias EHealth.Man.Templates.DeclarationRequestPrintoutForm

  import Ecto.Changeset, only: [get_field: 2, put_change: 3, add_error: 3]

  @ael_config Confex.get_map(:ehealth, AEL)

  def send_verification_code(_changeset) do
    {:ok, "Verification code was sent!"}
  end

  def generate_upload_urls(changeset) do
    id = get_field(changeset, :id)

    documents =
      Enum.map @ael_config[:declaration_request_offline_documents], fn document ->
        {:ok, %{"data" => result}} = AEL.generate_url(%{
          id: "declaration-#{id}",
          name: "#{document}.jpeg"
        })

        result
      end

    put_change(changeset, :documents, documents)
  end

  def generate_printout_form(changeset) do
    form_data = %{
      id: get_field(changeset, :id)
    }

    printout_content = DeclarationRequestPrintoutForm.render(form_data)

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
            error_message = "Error during Gandalf interaction. Result from Gandalf: #{inspect gandalf_decision}"

            add_error(changeset, :authentication_method_current, error_message)
        end
      _ ->
        error_message = "Error during MPI interaction. Result from MPI: #{inspect result}"

        add_error(changeset, :authentication_method_current, error_message)
    end
  end
end
