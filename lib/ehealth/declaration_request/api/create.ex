defmodule EHealth.DeclarationRequest.API.Create do
  @moduledoc false

  alias EHealth.API.MPI
  alias EHealth.API.Mithril
  alias EHealth.Man.Templates.DeclarationRequestPrintoutForm
  alias EHealth.API.OTPVerification
  alias Ecto.Changeset
  alias EHealth.PRM.PartyUsers
  alias EHealth.DeclarationRequest

  import Ecto.Changeset, only: [get_field: 2, get_change: 2, put_change: 3, add_error: 3]

  use Confex, otp_app: :ehealth

  @auth_na DeclarationRequest.authentication_method(:na)
  @auth_otp DeclarationRequest.authentication_method(:otp)
  @auth_offline DeclarationRequest.authentication_method(:offline)

  def send_verification_code(number) do
    OTPVerification.initialize(number)
  end

  def generate_printout_form(%Changeset{valid?: false} = changeset), do: changeset
  def generate_printout_form(changeset) do
    form_data = get_field(changeset, :data)
    authentication_method_current =
      case get_change(changeset, :authentication_method_default) do
        %{"type" => @auth_na} = default -> default
        _ -> get_change(changeset, :authentication_method_current)
      end

    case DeclarationRequestPrintoutForm.render(form_data, authentication_method_current) do
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

        authentication_method_current = prepare_auth_method_current(
          authentication_method["type"],
          authentication_method
        )

        put_change(changeset, :authentication_method_current, authentication_method_current)
      {:ok, %{"data" => []}} ->
        [authentication_method|_] = data["person"]["authentication_methods"]
        put_change(changeset, :authentication_method_current, prepare_auth_method_current(authentication_method))

      {:error, error_response} ->
        add_error(changeset, :authentication_method_current, format_error_response("MPI", error_response))
    end
  end

  def prepare_auth_method_current(%{"type" => @auth_offline}) do
    %{"type" => @auth_offline}
  end
  def prepare_auth_method_current(_) do
    %{"type" => @auth_na}
  end
  def prepare_auth_method_current(@auth_otp, %{"phone_number" => phone_number}) do
    %{
      "type" => @auth_otp,
      "number" => phone_number
    }
  end
  def prepare_auth_method_current(type, _authentication_method) do
    %{"type" => type}
  end

  def prepare_legal_entity_struct(legal_entity) do
    %{
      "id"             => legal_entity.id,
      "name"           => legal_entity.name,
      "short_name"     => legal_entity.short_name,
      "phones"         => legal_entity.phones,
      "legal_form"     => legal_entity.legal_form,
      "edrpou"         => legal_entity.edrpou,
      "public_name"    => legal_entity.public_name,
      "email"          => legal_entity.email,
      "addresses"      => legal_entity.addresses,
      "accreditation"  => legal_entity.medical_service_provider.accreditation,
      "licenses"       => legal_entity.medical_service_provider.licenses
    }
  end

  def prepare_employee_struct(employee) do
    %{
      "id"       => employee.id,
      "position" => employee.position,
      "party"    => %{
        "id"          => employee.party.id,
        "first_name"  => employee.party.first_name,
        "second_name" => employee.party.second_name,
        "last_name"   => employee.party.last_name,
        "phones"      => employee.party.phones,
        "tax_id"      => employee.party.tax_id
      }
    }
  end

  def prepare_division_struct(division) do
    %{
      "id"              => division.id,
      "type"            => division.type,
      "phones"          => division.phones,
      "name"            => division.name,
      "legal_entity_id" => division.legal_entity_id,
      "external_id"     => division.external_id,
      "email"           => division.email,
      "addresses"       => division.addresses
    }
  end

  defp fetch_users(result) do
    {:ok, Enum.map(result, &(Map.get(&1, :user_id)))}
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
    with {:ok, result} <- PartyUsers.get_party_users_by_party_id(party_id),
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
