defmodule Core.Repo.Migrations.CopyToDeclarationRequestDataColumns do
  use Ecto.Migration

  if Code.ensure_loaded?(Core.DeclarationRequests.DeclarationRequestTemp) do
    import Ecto.Query
    import Ecto.Changeset
    require Logger

    alias Core.DeclarationRequests.DeclarationRequest
    alias Core.DeclarationRequests.DeclarationRequestTemp
    alias Core.Repo

    @disable_ddl_transaction true

    def change do
      if temporary_table_empty?() do
        {:ok, init_value} = get_init_value()
        Repo.insert!(%DeclarationRequestTemp{id: 1, last_inserted_at: init_value})
      end

      process_batch(100, 10_000, 0, 0)
    end

    defp temporary_table_empty? do
      DeclarationRequestTemp
      |> select([dr], dr.id)
      |> Repo.one()
      |> case do
        nil -> true
        _ -> false
      end
    end

    defp get_init_value do
      DeclarationRequest
      |> select([dr], dr.inserted_at)
      |> order_by([dr], asc: dr.inserted_at)
      |> limit([dr], 1)
      |> Repo.one()
      |> case do
        nil -> DateTime.from_unix(0)
        value -> {:ok, DateTime.add(value, -1)}
      end
    end

    defp process_batch(batch_size, message_batch_size, processed_count, message_processed_count)
         when message_batch_size >= batch_size do
      last_inserted_at =
        DeclarationRequestTemp
        |> select([dr], dr.last_inserted_at)
        |> Repo.one()

      case DeclarationRequest
           |> select([dr], {dr.id, dr.data, dr.inserted_at})
           |> where([dr], dr.inserted_at > ^last_inserted_at)
           |> order_by([dr], asc: dr.inserted_at)
           |> limit([dr], ^batch_size)
           |> Repo.all() do
        batch when length(batch) < batch_size ->
          if message_processed_count >= 0 do
            Logger.info("#{DateTime.utc_now()}    Processed #{processed_count} records total")
          end

          :ok

        batch ->
          selection_ids =
            batch
            |> Enum.filter(fn {_, data, _} -> !is_nil(data) end)
            |> Enum.map(&elem(&1, 0))

          [{_, _, max_inserted_at} | _] = Enum.reverse(batch)

          case Enum.empty?(selection_ids) do
            true ->
              DeclarationRequestTemp
              |> Repo.get!(1)
              |> change(%{last_inserted_at: max_inserted_at})
              |> Repo.update!()

            _ ->
              Repo.transaction(fn ->
                from(dr in DeclarationRequest,
                  where: dr.id in ^selection_ids,
                  update: [
                    set: [
                      data_legal_entity_id: fragment("cast(?->'legal_entity'->>'id' as uuid)", dr.data),
                      data_employee_id: fragment("cast(?->'employee'->>'id' as uuid)", dr.data),
                      data_start_date_year:
                        fragment(
                          "cast(date_part('year', to_timestamp(?->>'start_date', 'YYYY-MM-DD') AT TIME ZONE 'UTC') as numeric)",
                          dr.data
                        ),
                      data_person_tax_id: fragment("?->'person'->>'tax_id'", dr.data),
                      data_person_first_name: fragment("?->'person'->>'first_name'", dr.data),
                      data_person_last_name: fragment("?->'person'->>'last_name'", dr.data),
                      data_person_birth_date: fragment("cast(?->'person'->>'birth_date' as date)", dr.data)
                    ]
                  ]
                )
                |> Repo.update_all([], timeout: :infinity)

                DeclarationRequestTemp
                |> Repo.get!(1)
                |> change(%{last_inserted_at: max_inserted_at})
                |> Repo.update!()
              end)
          end

          current_batch_size = length(batch)
          message_processed_count = message_processed_count + current_batch_size

          message_processed_count =
            if message_processed_count >= message_batch_size do
              Logger.info("#{DateTime.utc_now()}    Processed #{processed_count + current_batch_size} records total")
              message_processed_count - message_batch_size
            else
              message_processed_count
            end

          process_batch(batch_size, message_batch_size, processed_count + current_batch_size, message_processed_count)
      end
    end
  else
    def change() do
    end
  end
end
