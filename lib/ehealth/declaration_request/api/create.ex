defmodule EHealth.DeclarationRequest.API.Create do
  @moduledoc false

  alias EHealth.API.MediaStorage
  alias EHealth.API.MPI
  alias EHealth.API.PRM
  alias EHealth.API.Mithril
  alias EHealth.API.Gandalf
  alias EHealth.Man.Templates.DeclarationRequestPrintoutForm
  alias EHealth.API.OTPVerification
  alias Ecto.Changeset

  import Ecto.Changeset, only: [get_field: 2, put_change: 3, add_error: 3]

  use Confex, otp_app: :ehealth

  @files_storage_bucket Confex.fetch_env!(:ehealth, EHealth.API.MediaStorage)[:declaration_request_bucket]

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
    form_data = get_field(changeset, :data)

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

  defp fetch_users(result) do
    users =
      result
      |> Map.fetch!("data")
      |> Enum.map(fn(x) -> Map.get(x, "user_id") end)

    {:ok, users}
  end

  defp get_role_id(name) do
    with {:ok, results} <- Mithril.get_roles_by_name(name) do
      roles = Map.get(results, "data")
      case length(roles) do
        1 -> {:ok, roles |> List.first() |> Map.get("id")}
        _ -> {:error, "Role #{name} does not exist"}
      end
    end
  end

  defp filter_users_by_role(role_id, users) do
    user_roles_results = Enum.map(users, fn(user_id) -> Mithril.get_user_roles(user_id, %{}) end)
    error = Enum.find(user_roles_results, fn({k, _}) -> k == :error end)
    case error do
      nil -> {:ok, Enum.filter(user_roles_results, fn({:ok, result}) -> check_role(result, role_id) end)}
      err -> err
    end
  end

  defp get_user_id(user_roles) when length(user_roles) > 0 do
    {:ok, user_role} = List.last(user_roles)

    user_id =
      user_role
      |> Map.get("data")
      |> List.first()
      |> Map.get("user_id")

    {:ok, user_id}
  end
  defp get_user_id(_), do: {:error, "Current user is not a doctor"}

  defp check_role(user, role_id) do
    Enum.any?(Map.get(user, "data"), fn(user_role) -> Map.get(user_role, "role_id") == role_id end)
  end

  defp get_user_email(user_id) do
    with {:ok, user} <- Mithril.get_user_by_id(user_id), do: {:ok, get_in(user, ["data", "email"])}
  end

  defp get_party_email(party_id) do
    with {:ok, result} <- PRM.get_party_users_by_party_id(party_id),
      {:ok, users} <- fetch_users(result),
      {:ok, role_id} <- get_role_id("DOCTOR"),
      {:ok, user_roles} <- filter_users_by_role(role_id, users),
      {:ok, user_id} <- get_user_id(user_roles),
    do: get_user_email(user_id)
  end

  def put_party_email(%Changeset{valid?: false} = changeset), do: changeset
  def put_party_email(changeset) do
    party_id =
      changeset
      |> get_field(:data)
      |> get_in(["employee", "party", "id"])

    case get_party_email(party_id) do
      {:ok, email} ->
        put_in_data(changeset, ["employee", "party", "email"], email)
      {:error, error} when is_binary(error) ->
        add_error(changeset, :email, error)
      {:error, error_response} ->
        add_error(changeset, :email, format_error_response("microservice", error_response))
    end
  end

  defp put_in_data(changeset, keys, value) do
     new_data =
       changeset
       |> get_field(:data)
       |> put_in(keys, value)

     put_change(changeset, :data, new_data)
   end

  defp format_error_response(microservice, result) do
    "Error during #{microservice} interaction. Result from #{microservice}: #{inspect result}"
  end
end
