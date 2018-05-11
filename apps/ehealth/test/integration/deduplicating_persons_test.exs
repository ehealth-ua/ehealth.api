defmodule EHealth.Integration.DeduplicatingPersonsTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import Mox
  import ExUnit.CaptureLog

  alias EHealth.Declarations.Person

  require Logger

  setup :set_mox_global
  setup :verify_on_exit!

  describe "found_duplicates/0" do
    defmodule DeactivatingDuplicates do
      use MicroservicesHelper

      @person1 "abcf619e-ee57-4637-9bc8-3a465eca047c"
      @person2 "8060385c-c663-4f8f-bf8f-d8121216084e"

      Plug.Router.get "/declarations" do
        declarations =
          case conn.query_params do
            %{"person_id" => @person1} ->
              [
                %{
                  "id" => "1",
                  "person_id" => @person1
                },
                %{
                  "id" => "2",
                  "person_id" => @person1
                }
              ]

            %{"person_id" => @person2} ->
              [
                %{
                  "id" => "3",
                  "person_id" => @person2
                },
                %{
                  "id" => "4",
                  "person_id" => @person2
                }
              ]
          end

        send_resp(conn, 200, Poison.encode!(%{data: declarations}))
      end

      Plug.Router.patch "/persons/:id/declarations/actions/terminate" do
        Logger.info("Person #{id} got his declarations terminated.")
        # todo: use Mox.expect with n = 2 parameter
        send_resp(conn, 200, "")
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(DeactivatingDuplicates)
      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    @person1 "abcf619e-ee57-4637-9bc8-3a465eca047c"
    @person2 "8060385c-c663-4f8f-bf8f-d8121216084e"
    @master_person_id "c3c765eb-378a-4c23-a36e-ad12ae073960"
    @updated_candidate %{}

    @person_status_new Person.status(:new)
    @person_status_merged Person.status(:merged)
    @person_status_inactive Person.status(:inactive)

    test "duplicate persons are marked as MERGED, declarations are deactivated" do
      expect(MPIMock, :get_merge_candidates, fn params, _headers ->
        assert %{status: @person_status_new} = params

        merge_candidates = [
          %{"id" => "mc_1", "person_id" => @person1, "master_person_id" => @master_person_id},
          %{"id" => "mc_2", "person_id" => @person2, "master_person_id" => @master_person_id}
        ]

        {:ok, %{"data" => merge_candidates}}
      end)

      expect(MPIMock, :update_person, fn @master_person_id, params, _headers ->
        Logger.info("Master person #{@master_person_id} was updated with #{inspect(params)}.")
        %{merged_ids: [@person1, @person2]} = params
        {:ok, %{"data" => @updated_candidate}}
      end)

      expect(MPIMock, :update_person, fn @person1, params, _headers ->
        Logger.info("Person #{@person1} was deactivated.")
        %{status: @person_status_inactive} = params
        {:ok, %{"data" => @updated_candidate}}
      end)

      expect(MPIMock, :update_person, fn @person2, params, _headers ->
        Logger.info("Person #{@person2} was deactivated.")
        %{status: @person_status_inactive} = params
        {:ok, %{"data" => @updated_candidate}}
      end)

      expect(MPIMock, :update_merge_candidate, fn "mc_1", params, _headers ->
        Logger.info("Candidate mc_1 was merged.")
        %{status: @person_status_merged} = params
        {:ok, %{"data" => @updated_candidate}}
      end)

      expect(MPIMock, :update_merge_candidate, fn "mc_2", params, _headers ->
        Logger.info("Candidate mc_2 was merged.")
        %{status: @person_status_merged} = params
        {:ok, %{"data" => @updated_candidate}}
      end)

      captured_log =
        capture_log(fn ->
          response = post(build_conn(), "/internal/deduplication/found_duplicates")
          Process.sleep(1000)

          assert "OK" = text_response(response, 200)
        end)

      assert captured_log =~ "Master person c3c765eb-378a-4c23-a36e-ad12ae073960 was updated"
      assert captured_log =~ "Candidate mc_1 was merged."
      assert captured_log =~ "Candidate mc_2 was merged."
      assert captured_log =~ "Person 8060385c-c663-4f8f-bf8f-d8121216084e was deactivated."
      assert captured_log =~ "Person abcf619e-ee57-4637-9bc8-3a465eca047c was deactivated."
      assert captured_log =~ "Person 8060385c-c663-4f8f-bf8f-d8121216084e got his declarations terminated."
      assert captured_log =~ "Person abcf619e-ee57-4637-9bc8-3a465eca047c got his declarations terminated."
    end
  end
end
