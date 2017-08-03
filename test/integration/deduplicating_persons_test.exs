defmodule EHealth.Integration.DeduplicatingPersonsTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  require Logger

  import ExUnit.CaptureLog

  describe "found_duplicates/0" do
    defmodule DeactivatingDuplicates do
      use MicroservicesHelper

      @person1 "abcf619e-ee57-4637-9bc8-3a465eca047c"
      @person2 "8060385c-c663-4f8f-bf8f-d8121216084e"

      Plug.Router.get "/merge_candidates" do
        %{"status" => "NEW"} = conn.query_params

        merge_candidates = [
          %{ "person_id" => @person1 },
          %{ "person_id" => @person2 }
        ]

        send_resp(conn, 200, Poison.encode!(%{data: merge_candidates}))
      end

      Plug.Router.patch "/merge_candidates/#{@person1}" do
        Logger.info("Candidate #{@person1} was merged.")
        updated_candidate = %{}
        send_resp(conn, 200, Poison.encode!(%{data: updated_candidate}))
      end

      Plug.Router.patch "/merge_candidates/#{@person2}" do
        Logger.info("Candidate #{@person2} was merged.")
        updated_candidate = %{}
        send_resp(conn, 200, Poison.encode!(%{data: updated_candidate}))
      end

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
        Logger.info("Candidate #{id} got his declarations terminated.")
        # TODO: how to test this was actually called TWO times?
        send_resp(conn, 200, "")
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(DeactivatingDuplicates)

      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit fn ->
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "duplicate persons are marked as MERGED, declarations are deactivated" do
      result = capture_log fn ->
        response =
          build_conn()
          |> post("/internal/deduplication/found_duplicates")

        Process.sleep(1000)

        assert "OK" = text_response(response, 200)
      end

      assert result =~ "Candidate 8060385c-c663-4f8f-bf8f-d8121216084e was merged."
      assert result =~ "Candidate abcf619e-ee57-4637-9bc8-3a465eca047c was merged."
      assert result =~ "Candidate 8060385c-c663-4f8f-bf8f-d8121216084e got his declarations terminated."
      assert result =~ "Candidate abcf619e-ee57-4637-9bc8-3a465eca047c got his declarations terminated."
    end
  end
end
