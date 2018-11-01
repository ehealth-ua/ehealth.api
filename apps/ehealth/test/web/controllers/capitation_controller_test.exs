defmodule EHealth.Web.CapitationControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias Ecto.UUID

  describe "List capitation reports" do
    test "get capitation report list success", %{conn: conn} do
      report_id = UUID.generate()

      expect(ReportMock, :get_capitation_list, fn _params, _headers ->
        {:ok,
         %{
           "data" => [
             %{
               "billing_date" => "2018-06-01",
               "id" => report_id,
               "inserted_at" => "2018-06-25T15:47:09.351803"
             }
           ],
           "meta" => %{"code" => 200},
           "paging" => %{
             "page_number" => 2,
             "page_size" => 1,
             "total_entries" => 2,
             "total_pages" => 2
           }
         }}
      end)

      response =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(capitation_path(conn, :index, %{page_size: 1, page: 2}))
        |> json_response(200)

      assert %{"data" => [%{"id" => ^report_id}], "paging" => %{"page_number" => 2, "page_size" => 1}} = response
    end
  end

  describe "capitation reports details" do
    test "capitation report details success", %{conn: conn} do
      nhs(3)
      report_id = UUID.generate()

      expect(ReportMock, :get_capitation_details, 3, fn _params, _headers ->
        {:ok,
         %{
           "data" => [
             %{
               "billing_date" => "2018-06-01",
               "capitation_contracts" => [
                 %{
                   "contract_id" => "790778e6-b4ad-4396-992d-d85ca6dd9365",
                   "contract_number" => "contract-number-4381",
                   "details" => [
                     %{
                       "attributes" => [%{"40-60" => 2}, %{"19-39" => 2}, %{"0-18" => 1}],
                       "mountain_group" => true
                     },
                     %{
                       "attributes" => [%{"19-39" => 4}, %{"0-18" => 3}, %{"40-60" => 4}],
                       "mountain_group" => false
                     }
                   ],
                   "total" => [%{"19-39" => 6}, %{"0-18" => 4}, %{"40-60" => 6}]
                 },
                 %{
                   "contract_id" => "0b13a1b2-007d-48f9-9af7-302205ff1523",
                   "contract_number" => "contract-number-5128",
                   "details" => [
                     %{
                       "attributes" => [%{"0-18" => 4}, %{"19-39" => 3}, %{"40-60" => 1}],
                       "mountain_group" => false
                     },
                     %{
                       "attributes" => [%{"40-60" => 1}, %{"19-39" => 3}, %{"0-18" => 2}],
                       "mountain_group" => true
                     }
                   ],
                   "total" => [%{"0-18" => 6}, %{"19-39" => 6}, %{"40-60" => 2}]
                 },
                 %{
                   "contract_id" => "77f5e5ae-7e77-468d-b32e-f3a50c21c4f9",
                   "contract_number" => "contract-number-7395",
                   "details" => [
                     %{
                       "attributes" => [%{"19-39" => 1}, %{"40-60" => 3}, %{"0-18" => 3}],
                       "mountain_group" => false
                     },
                     %{
                       "attributes" => [%{"19-39" => 1}, %{"0-18" => 1}, %{"40-60" => 2}],
                       "mountain_group" => true
                     }
                   ],
                   "total" => [%{"0-18" => 4}, %{"40-60" => 5}, %{"19-39" => 2}]
                 }
               ],
               "edrpou" => "edrpou",
               "legal_entity_id" => "2ec2b749-41d0-461b-aa02-1abd7ccbd86b",
               "legal_entity_name" => "Blastoise",
               "report_id" => "9ce44b25-cf35-4629-a5ee-dfed7470daaf"
             }
           ],
           "paging" => %{"page_number" => 2, "page_size" => 1}
         }}
      end)

      check_response = fn data ->
        Enum.each(data, fn legal ->
          Enum.each(~w(id report_id legal_entity_name legal_entity_id edrpou billing_date capitation_contracts), fn k ->
            assert Map.has_key?(legal, k)

            assert %{"id" => "edrpou-9ce44b25-cf35-4629-a5ee-dfed7470daaf"} = legal

            Enum.each(legal["capitation_contracts"], fn contract ->
              Enum.each(["contract_id", "contract_number", "details", "total"], fn k ->
                assert Map.has_key?(contract, k)
              end)

              Enum.each(contract["details"], fn detail ->
                Enum.each(~w(attributes mountain_group), fn k -> assert Map.has_key?(detail, k) end)
                assert is_map(detail["attributes"])
                assert is_boolean(detail["mountain_group"])
              end)
            end)
          end)
        end)
      end

      response =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(capitation_path(conn, :details, %{page_size: 1, page: 2}))
        |> json_response(200)

      assert %{"data" => data, "paging" => %{"page_number" => 2, "page_size" => 1}} = response

      check_response.(data)

      response =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(capitation_path(conn, :details, %{page_size: 1, page: 1, report_id: report_id}))
        |> json_response(200)

      assert %{"data" => data} = response

      check_response.(data)

      response =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(capitation_path(conn, :details, %{page_size: 1, page: 1, report_id: report_id, edrpou: "EDRPOU"}))
        |> json_response(200)

      assert %{"data" => data} = response

      check_response.(data)
    end

    test "capitation report details succes when edrpou is nil", %{conn: conn} do
      nhs()

      expect(ReportMock, :get_capitation_details, 3, fn _params, _headers ->
        {:ok,
         %{
           "data" => [
             %{
               "billing_date" => "2018-06-01",
               "capitation_contracts" => [
                 %{
                   "contract_id" => "790778e6-b4ad-4396-992d-d85ca6dd9365",
                   "contract_number" => "contract-number-4381",
                   "details" => [
                     %{
                       "attributes" => [%{"40-60" => 2}, %{"19-39" => 2}, %{"0-18" => 1}],
                       "mountain_group" => true
                     },
                     %{
                       "attributes" => [%{"19-39" => 4}, %{"0-18" => 3}, %{"40-60" => 4}],
                       "mountain_group" => false
                     }
                   ],
                   "total" => [%{"19-39" => 6}, %{"0-18" => 4}, %{"40-60" => 6}]
                 },
                 %{
                   "contract_id" => "0b13a1b2-007d-48f9-9af7-302205ff1523",
                   "contract_number" => "contract-number-5128",
                   "details" => [
                     %{
                       "attributes" => [%{"0-18" => 4}, %{"19-39" => 3}, %{"40-60" => 1}],
                       "mountain_group" => false
                     },
                     %{
                       "attributes" => [%{"40-60" => 1}, %{"19-39" => 3}, %{"0-18" => 2}],
                       "mountain_group" => true
                     }
                   ],
                   "total" => [%{"0-18" => 6}, %{"19-39" => 6}, %{"40-60" => 2}]
                 },
                 %{
                   "contract_id" => "77f5e5ae-7e77-468d-b32e-f3a50c21c4f9",
                   "contract_number" => "contract-number-7395",
                   "details" => [
                     %{
                       "attributes" => [%{"19-39" => 1}, %{"40-60" => 3}, %{"0-18" => 3}],
                       "mountain_group" => false
                     },
                     %{
                       "attributes" => [%{"19-39" => 1}, %{"0-18" => 1}, %{"40-60" => 2}],
                       "mountain_group" => true
                     }
                   ],
                   "total" => [%{"0-18" => 4}, %{"40-60" => 5}, %{"19-39" => 2}]
                 }
               ],
               "edrpou" => nil,
               "legal_entity_id" => "2ec2b749-41d0-461b-aa02-1abd7ccbd86b",
               "legal_entity_name" => "Blastoise",
               "report_id" => "9ce44b25-cf35-4629-a5ee-dfed7470daaf"
             }
           ],
           "paging" => %{"page_number" => 2, "page_size" => 1}
         }}
      end)

      response =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(capitation_path(conn, :details, %{page_size: 1, page: 2}))
        |> json_response(200)

      assert %{"data" => _, "paging" => %{"page_number" => 2, "page_size" => 1}} = response
    end
  end
end
