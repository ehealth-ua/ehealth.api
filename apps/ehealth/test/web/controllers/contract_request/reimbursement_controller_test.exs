defmodule EHealth.Web.ContractRequest.ReimbursementControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Core.Expectations.Signature
  import Mox

  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Contracts.ReimbursementContract
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias Core.Utils.NumberGenerator
  alias Ecto.UUID
  alias NExJsonSchema.Validator, as: JsonValidator

  setup :verify_on_exit!

  @msp LegalEntity.type(:msp)
  @pharmacy LegalEntity.type(:pharmacy)
  @reimbursement ReimbursementContractRequest.type()
  @path_type String.downcase(@reimbursement)

  describe "successful creation reimbursement contract request" do
    setup %{conn: conn} do
      expect(MediaStorageMock, :create_signed_url, 6, fn _, _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :get_signed_content, 2, fn _ -> {:ok, %{body: ""}} end)
      expect(MediaStorageMock, :delete_file, 2, fn _ -> {:ok, nil} end)
      expect(MediaStorageMock, :save_file, 2, fn _, _, _, _, _ -> {:ok, nil} end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"ETag", Jason.encode!(resource)}]}}
      end)

      %{conn: conn}
    end

    test "with contract_number", %{conn: conn} do
      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      contract_number = NumberGenerator.generate_from_sequence(1, 1)

      insert(
        :prm,
        :reimbursement_contract,
        contract_number: contract_number,
        status: ReimbursementContract.status(:verified),
        contractor_legal_entity: legal_entity,
        medical_program: medical_program
      )

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.merge(%{
          "contractor_owner_id" => owner.id,
          "contract_number" => contract_number
        })
        |> Map.drop(~w(start_date end_date))

      drfo_signed_content(params, legal_entity.edrpou, party_user.party.last_name)

      conn
      |> put_client_id_header(legal_entity.id)
      |> put_consumer_id_header(user_id)
      |> put_req_header("drfo", legal_entity.edrpou)
      |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
      |> json_response(201)
      |> Map.get("data")
      |> assert_response()
    end

    test "without contract_number", %{conn: conn} do
      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.put("contractor_owner_id", owner.id)

      drfo_signed_content(params, legal_entity.edrpou, party_user.party.last_name)

      conn
      |> put_client_id_header(legal_entity.id)
      |> put_consumer_id_header(user_id)
      |> put_req_header("drfo", legal_entity.edrpou)
      |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
      |> json_response(201)
      |> Map.get("data")
      |> assert_response()
    end
  end

  describe "create reimbursement contract request" do
    test "invalid previous contract type", %{conn: conn} do
      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      contract_number = NumberGenerator.generate_from_sequence(1, 1)

      insert(
        :prm,
        :capitation_contract,
        contract_number: contract_number,
        status: ReimbursementContract.status(:verified),
        contractor_legal_entity: legal_entity
      )

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.merge(%{
          "contractor_owner_id" => owner.id,
          "contract_number" => contract_number
        })
        |> Map.drop(~w(start_date end_date))

      drfo_signed_content(params, legal_entity.edrpou, party_user.party.last_name)

      reason =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
        |> json_response(409)
        |> get_in(~w(error message))

      assert "Submitted contract type does not correspond to previously created content" == reason
    end

    test "invalid legal_entity client_type", %{conn: conn} do
      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data(@msp)

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.merge(%{
          "contractor_owner_id" => owner.id,
          "contractor_legal_entity_id" => legal_entity.id
        })
        |> Map.drop(~w(start_date end_date))

      drfo_signed_content(params, legal_entity.edrpou, party_user.party.last_name)

      reason =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post(
          contract_request_path(conn, :create, @path_type, UUID.generate()),
          signed_content_params(params)
        )
        |> json_response(409)
        |> get_in(~w(error message))

      assert "Contract type \"#{@reimbursement}\" is not allowed for legal_entity with type \"#{@msp}\"" == reason
    end
  end

  describe "invalid medical program" do
    test "program id not match with previously created request", %{conn: conn} do
      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      contract_number = NumberGenerator.generate_from_sequence(1, 1)

      insert(
        :prm,
        :reimbursement_contract,
        contract_number: contract_number,
        status: ReimbursementContract.status(:verified),
        contractor_legal_entity: legal_entity,
        medical_program: medical_program
      )

      params =
        division
        |> prepare_reimbursement_params(legal_entity)
        |> Map.put("contractor_owner_id", owner.id)
        |> Map.put("contract_number", contract_number)
        |> Map.drop(~w(start_date end_date))

      drfo_signed_content(params, legal_entity.edrpou, party_user.party.last_name)

      reason =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
        |> json_response(409)
        |> get_in(~w(error message))

      assert "Submitted medical_program_id does not correspond to previously created content" == reason
    end

    test "medical program not exist", %{conn: conn} do
      %{
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      params =
        division
        |> prepare_reimbursement_params(legal_entity)
        |> Map.put("contractor_owner_id", owner.id)

      drfo_signed_content(params, legal_entity.edrpou, party_user.party.last_name)

      assert [err] =
               conn
               |> put_client_id_header(legal_entity.id)
               |> put_consumer_id_header(user_id)
               |> put_req_header("drfo", legal_entity.edrpou)
               |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "Reimbursement program with such id does not exist" == hd(err["rules"])["description"]
    end

    test "medical program inactive", %{conn: conn} do
      medical_program = insert(:prm, :medical_program, is_active: false)

      %{
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.put("contractor_owner_id", owner.id)

      drfo_signed_content(params, legal_entity.edrpou, party_user.party.last_name)

      reason =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
        |> json_response(409)
        |> get_in(~w(error message))

      assert "Reimbursement program is not active" == reason
    end
  end

  defp prepare_reimbursement_params(division, medical_program) do
    now = Date.utc_today()
    start_date = Date.to_iso8601(Date.add(now, 10))
    end_date = Date.to_iso8601(Date.add(now, 30))

    %{
      "contractor_owner_id" => UUID.generate(),
      "contractor_base" => "на підставі закону про Медичне обслуговування населення",
      "contractor_payment_details" => %{
        "bank_name" => "Банк номер 1",
        "MFO" => "351005",
        "payer_account" => "32009102701026"
      },
      "id_form" => "5",
      "contractor_divisions" => [division.id],
      "start_date" => start_date,
      "end_date" => end_date,
      "statute_md5" => "media/upload_contract_request_statute.pdf",
      "additional_document_md5" => "media/upload_contract_request_additional_document.pdf",
      "medical_program_id" => medical_program.id,
      "consent_text" =>
        "Цією заявою Заявник висловлює бажання укласти договір про медичне обслуговування населення за програмою державних гарантій медичного обслуговування населення (далі – Договір) на умовах, визначених в оголошенні про укладення договорів про медичне обслуговування населення (далі – Оголошення). Заявник підтверджує, що: 1. на момент подання цієї заяви Заявник має чинну ліцензію на провадження господарської діяльності з медичної практики та відповідає ліцензійним умовам з медичної практики; 2. Заявник надає медичні послуги, пов’язані з первинною медичною допомогою (далі – ПМД); 3. Заявник зареєстрований в електронній системі охорони здоров’я (далі – Система); 4. уповноважені особи та медичні працівники, які будуть залучені до виконання Договору, зареєстровані в Системі та отримали електронний цифровий підпис (далі – ЕЦП); 5. в кожному місці надання медичних послуг Заявника наявне матеріально-технічне оснащення, передбачене розділом І Примірного табелю матеріально-технічного оснащення закладів охорони здоров’я та фізичних осіб – підприємців, які надають ПМД, затвердженого наказом Міністерства охорони здоров’я України від 26 січня 2018 року № 148; 6. установчими або іншими документами не обмежено право керівника Заявника підписувати договори від імені Заявника без попереднього погодження власника. Якщо таке право обмежено, у тому числі щодо укладання договорів, ціна яких перевищує встановлену суму, Заявник повідомить про це Національну службу здоров’я та отримає необхідні погодження від власника до моменту підписання договору зі сторони Заявника; 7. інформація, зазначена Заявником у цій Заяві та доданих до неї документах, а також інформація, внесена Заявником (його уповноваженими особами) до Системи, є повною та достовірною. Заявник усвідомлює, що у разі зміни інформації, зазначеної Заявником у цій заяві та (або) доданих до неї документах Заявник зобов’язаний повідомити про такі зміни НСЗУ протягом трьох робочих днів з дня настання таких змін шляхом надсилання інформації про такі зміни на електронну пошту dohovir@nszu.gov.ua, з одночасним внесенням таких змін в Систему. Заявник усвідомлює, що законодавством України передбачена відповідальність за подання недостовірної інформації органам державної влади."
    }
  end

  defp prepare_data(legal_entity_type \\ @pharmacy) do
    user_id = UUID.generate()
    party_user = insert(:prm, :party_user, user_id: user_id)
    legal_entity = insert(:prm, :legal_entity, type: legal_entity_type)
    medical_program = insert(:prm, :medical_program)

    division =
      insert(
        :prm,
        :division,
        legal_entity: legal_entity,
        phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
      )

    owner =
      insert(
        :prm,
        :employee,
        employee_type: Employee.type(:owner),
        party: party_user.party,
        legal_entity_id: legal_entity.id
      )

    %{
      legal_entity: legal_entity,
      medical_program: medical_program,
      division: division,
      user_id: user_id,
      owner: owner,
      party_user: party_user
    }
  end

  defp signed_content_params(content) do
    %{
      "signed_content" => content |> Jason.encode!() |> Base.encode64(),
      "signed_content_encoding" => "base64"
    }
  end

  defp assert_response(resp) do
    schema =
      "../core/specs/json_schemas/contract_request/reimbursement_contract_request_show_response.json"
      |> File.read!()
      |> Jason.decode!()

    assert :ok = JsonValidator.validate(schema, resp)
  end
end
