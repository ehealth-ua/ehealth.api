defmodule Core.Registers.API do
  @moduledoc false

  use Core.Search, Core.Repo

  import Ecto.Changeset

  alias Core.Dictionaries
  alias Core.Dictionaries.Dictionary
  alias Core.Ecto.Base64
  alias Core.Persons
  alias Core.Registers.Register
  alias Core.Registers.RegisterEntry
  alias Core.Registers.SearchRegisterEntries
  alias Core.Registers.SearchRegisters
  alias Core.Repo
  alias Core.Validators.DeathDate
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Ecto.UUID

  @mpi_api Application.get_env(:core, :api_resolvers)[:mpi]
  @ops_api Application.get_env(:core, :api_resolvers)[:ops]

  @status_matched RegisterEntry.status(:matched)
  @status_not_found RegisterEntry.status(:not_found)
  @status_error RegisterEntry.status(:error)
  @status_processed RegisterEntry.status(:processed)

  @status_new Register.status(:new)
  @status_processed Register.status(:processed)
  @status_invalid Register.status(:invalid)

  @person_status_inactive "inactive"

  @required_register_fields ~w(
    file_name
    type
    status
    entity_type
    inserted_by
    updated_by
  )a
  @optional_register_fields ~w(
    errors
  )a

  @required_qty_fields ~w(
    total
    errors
    not_found
    processed
  )a

  @required_register_entry_fields ~w(
    status
    document_type
    document_number
    register_id
    inserted_by
    updated_by
  )a

  @optional_register_entry_fields ~w(
    person_id
  )a

  def list_registers(params \\ %{}) do
    %SearchRegisters{}
    |> cast(params, SearchRegisters.__schema__(:fields))
    |> search(params, Register)
  end

  def list_register_entries(params \\ %{}) do
    %SearchRegisterEntries{}
    |> cast(params, SearchRegisterEntries.__schema__(:fields))
    |> search(params, RegisterEntry)
  end

  def get_search_query(entity, changes) when map_size(changes) > 0 do
    params = Enum.filter(changes, fn {k, v} -> !is_tuple(v) && k not in ~W(inserted_at_from inserted_at_to)a end)

    q =
      entity
      |> where(^params)
      |> preload_register(entity)

    changes
    |> Enum.reduce(q, fn {key, val}, query ->
      case key do
        :inserted_at_from -> where(query, [r], r.inserted_at >= ^date_to_datetime(val))
        :inserted_at_to -> where(query, [r], r.inserted_at <= ^date_to_end_datetime(val))
        _ -> query
      end
    end)
    |> order_by([r], desc: r.inserted_at)
  end

  def get_search_query(entity, changes) do
    entity
    |> super(changes)
    |> order_by([r], desc: r.inserted_at)
    |> preload_register(entity)
  end

  defp preload_register(query, RegisterEntry) do
    query
    |> join(:left, [re], r in assoc(re, :register))
    |> preload([..., r], register: r)
  end

  defp preload_register(query, _), do: query

  defp date_to_datetime(date) do
    date
    |> Date.to_string()
    |> Timex.parse!("{YYYY}-{0M}-{0D}")
  end

  defp date_to_end_datetime(date) do
    date
    |> date_to_datetime()
    |> Timex.end_of_day()
  end

  def process_register_file(attrs, author_id) do
    with %Ecto.Changeset{valid?: true} <- cast({%{}, %{file: Base64}}, attrs, [:file]),
         :ok <- JsonSchema.validate(:registers, attrs),
         register_data <- prepare_register_data(attrs, author_id),
         {:ok, %Register{} = register} <- create_register(register_data),
         :ok <- batch_create_register_entries(register, attrs, attrs["reason_description"], author_id),
         register_update_data <- prepare_register_update_data([], @status_new),
         {:ok, register} <- update_register(register, register_update_data) do
      {:ok, register}
    end
  end

  defp prepare_register_data(attrs, author_id) do
    Map.merge(attrs, %{
      "status" => @status_new,
      "inserted_by" => author_id,
      "updated_by" => author_id
    })
  end

  def batch_create_register_entries(register, %{"file" => base64file}, reason_desc, author_id) do
    with {:ok, parsed_csv} <- parse_csv(base64file),
         {:ok, headers} <- fetch_headers(parsed_csv),
         :ok <- validate_csv_headers(headers),
         {:ok, allowed_types} <- get_allowed_types(register) do
      try do
        parent = self()

        Task.async(fn ->
          processed_data =
            parsed_csv
            |> Enum.with_index(1)
            |> Enum.reduce([], fn {row, index}, acc ->
              if rem(index, 100) == 0 do
                update_register(register, prepare_register_update_data(acc, @status_new))
              end

              acc ++ [process_register_entry(row, register, allowed_types, reason_desc, author_id)]
            end)

          send(parent, update_register(register, prepare_register_update_data(processed_data)))
        end)

        :ok
      catch
        :exit, _ ->
          invalid_register(register)
      end
    else
      err ->
        invalid_register(register)
        err
    end
  rescue
    _ -> invalid_register(register)
  catch
    _ -> invalid_register(register)
  end

  defp invalid_register(%Register{} = register) do
    register
    |> changeset(%{"status" => @status_invalid})
    |> Repo.update()
  end

  defp parse_csv(file) do
    {:ok,
     file
     |> Base.decode64!()
     |> String.split("\n")
     |> CSV.decode(headers: true)}
  end

  defp get_allowed_types(%Register{entity_type: "patient"}) do
    case Dictionaries.get_dictionary("REGISTER_DOCUMENTS") do
      %Dictionary{values: %{"PATIENT" => document_types}} -> {:ok, Map.keys(document_types) ++ ["MPI_ID"]}
      _ -> Error.dump("Type not allowed")
    end
  end

  defp get_allowed_types(%Register{entity_type: "declaration"}) do
    case Dictionaries.get_dictionary("REGISTER_DOCUMENTS") do
      %Dictionary{values: values} -> {:ok, values |> Map.get("DECLARATION") |> Map.keys()}
      _ -> Error.dump("Type not allowed")
    end
  end

  defp fetch_headers(csv) do
    case Enum.take(csv, 1) do
      [ok: headers] -> {:ok, headers}
      _ -> Error.dump("Invalid CSV headers")
    end
  end

  defp validate_csv_headers(headers) do
    values = headers |> Map.keys() |> Enum.map(&String.downcase/1) |> MapSet.new()

    cond do
      values == MapSet.new(["type", "number"]) -> :ok
      values == MapSet.new(["type", "number", "death_date"]) -> :ok
      true -> Error.dump("Invalid CSV headers")
    end
  end

  defp process_register_entry(
         {:ok, entry_data},
         %Register{entity_type: "patient"} = register,
         allowed_types,
         reason_desc,
         author_id
       ) do
    with :ok <- validate_csv_type(entry_data, allowed_types),
         :ok <- validate_csv_number(entry_data),
         :ok <- validate_csv_death_date(entry_data),
         :ok <- validate_csv_mpi_id(entry_data),
         mpi_response <- search_person(entry_data),
         :ok <- validate_death_date(entry_data, mpi_response) do
      entry_data
      |> Map.merge(%{
        "document_type" => entry_data["type"],
        "document_number" => entry_data["number"],
        "register_id" => register.id,
        "updated_by" => register.inserted_by,
        "inserted_by" => register.inserted_by
      })
      |> set_entry_status(mpi_response)
      |> terminate_person_declaration_and_create_entry(register.type, reason_desc, author_id)
    end
  end

  defp process_register_entry(
         {:ok, entry_data},
         %Register{entity_type: "declaration"} = register,
         allowed_types,
         reason_desc,
         author_id
       ) do
    with :ok <- validate_csv_type(entry_data, allowed_types),
         :ok <- validate_csv_number(entry_data) do
      entry_data
      |> Map.merge(%{
        "document_type" => entry_data["type"],
        "document_number" => entry_data["number"],
        "register_id" => register.id,
        "updated_by" => register.inserted_by,
        "inserted_by" => register.inserted_by
      })
      |> terminate_declaration(register.type, reason_desc, author_id)
      |> create_register_entry()
    end
  end

  defp process_register_entry(err, _, _, _, _), do: err

  defp validate_csv_type(%{"type" => type}, allowed_types) do
    case type in allowed_types do
      true ->
        :ok

      false ->
        {:error, "Invalid type - expected one of #{Enum.join(allowed_types, ", ")} on line "}
    end
  end

  defp validate_csv_number(%{"number" => number}) when is_binary(number) and byte_size(number) > 0, do: :ok

  defp validate_csv_number(_), do: {:error, "Invalid number - expected non empty string on line "}

  defp validate_csv_death_date(%{"death_date" => death_date}) when byte_size(death_date) > 0 do
    case DeathDate.validate(death_date) do
      :ok -> :ok
      :error -> {:error, "Invalid death_date on line "}
    end
  end

  defp validate_csv_death_date(_), do: :ok

  defp validate_death_date(%{"death_date" => death_date}, {:ok, persons}) when byte_size(death_date) > 0 do
    with {:ok, death_date} <- Date.from_iso8601(death_date) do
      Enum.reduce_while(persons, :ok, fn person, _acc ->
        if Date.compare(death_date, person.birth_date) in [:gt, :eq],
          do: {:cont, :ok},
          else: {:halt, {:error, "Invalid death_date: it is less than birth_date on line "}}
      end)
    else
      _ -> {:error, "Invalid death_date on line "}
    end
  end

  defp validate_death_date(_, _), do: :ok

  def validate_csv_mpi_id(%{"type" => "MPI_ID", "number" => number}) do
    case UUID.cast(number) do
      {:ok, _} -> :ok
      :error -> {:error, "Invalid number - MPI_ID is not UUID on line "}
    end
  end

  def validate_csv_mpi_id(_), do: :ok

  defp search_person(entry_data) do
    if entry_data["type"] == "MPI_ID",
      do: Persons.search_persons(%{"id" => entry_data["number"]}, ~w(id birth_date)a, read_only: true),
      else: Persons.search_persons(entry_data, ~w(id birth_date)a, read_only: true)
  end

  defp set_entry_status(entry_data, {:ok, []}) do
    {@status_not_found, [Map.put(entry_data, "status", @status_not_found)]}
  end

  defp set_entry_status(entry_data, {:ok, persons}) do
    entry_data = Enum.map(persons, &Map.merge(entry_data, %{"person_id" => &1.id, "status" => @status_matched}))
    {@status_matched, entry_data}
  end

  defp set_entry_status(entry_data, _) do
    {@status_not_found, [Map.put(entry_data, "status", @status_error)]}
  end

  defp terminate_person_declaration_and_create_entry(
         {@status_matched, entries},
         type,
         reason_desc,
         author_id
       ) do
    entries
    |> Enum.map(
      &(&1
        |> maybe_terminate_person_declaration(type, reason_desc)
        |> maybe_deactivate_person(author_id)
        |> create_register_entry())
    )
  end

  defp terminate_person_declaration_and_create_entry({_, entries}, _type, _reason_desc, _author_id) do
    Enum.map(entries, &create_register_entry/1)
  end

  defp terminate_declaration(entry_data, type, reason_description, author_id) do
    declaration_id = entry_data["document_number"]

    with {:ok, %{"data" => declaration}} <- @ops_api.get_declaration_by_id(declaration_id, []) do
      if declaration["status"] in ["terminated", "closed", "rejected"] do
        Map.put(entry_data, "status", @status_processed)
      else
        case @ops_api.terminate_declaration(
               declaration_id,
               %{
                 "updated_by" => author_id,
                 "reason" => "auto_#{type}",
                 "reason_description" => reason_description
               },
               []
             ) do
          {:ok, _} ->
            Map.put(entry_data, "status", @status_matched)

          {:error,
           %{
             "meta" => %{
               "code" => 404
             }
           }} ->
            Map.put(entry_data, "status", @status_not_found)

          _ ->
            Map.put(entry_data, "status", @status_error)
        end
      end
    else
      {:error,
       %{
         "meta" => %{
           "code" => 404
         }
       }} ->
        Map.put(entry_data, "status", @status_not_found)

      _ ->
        Map.put(entry_data, "status", @status_error)
    end
  end

  defp maybe_terminate_person_declaration(
         %{"status" => @status_matched} = entry_data,
         type,
         reason_desc
       ) do
    case @ops_api.terminate_person_declarations(
           entry_data["person_id"],
           entry_data["inserted_by"],
           "auto_" <> type,
           reason_desc,
           []
         ) do
      {:ok, _} ->
        entry_data

      _ ->
        Map.put(entry_data, "status", @status_error)
    end
  end

  defp maybe_terminate_person_declaration(entry_data, _type, _reason_desc), do: entry_data

  defp maybe_deactivate_person(%{"status" => @status_matched, "person_id" => person_id} = entry_data, author_id) do
    update_data = put_death_date(%{"status" => @person_status_inactive}, entry_data["death_date"])

    @mpi_api.update_person(person_id, update_data, "x-consumer-id": author_id)
    # don't care about MPI response
    entry_data
  end

  defp maybe_deactivate_person(entry_data, _author_id), do: entry_data

  defp put_death_date(params, ""), do: params
  defp put_death_date(params, nil), do: params
  defp put_death_date(params, value), do: Map.put(params, "death_date", value)

  defp prepare_register_update_data(processed_entries, status \\ @status_processed) do
    acc = %{
      status: status,
      qty: %{total: 0, not_found: 0, errors: 0, processed: 0},
      errors: [],
      # starts with first because of CSV headers
      tmp_line: 1
    }

    Enum.reduce(processed_entries, acc, fn entries, acc ->
      acc = Map.update!(acc, :tmp_line, &(&1 + 1))
      count_register_qty(entries, acc)
    end)
  end

  defp count_register_qty({:ok, %RegisterEntry{status: @status_matched}}, acc) do
    increment_qty(acc, :processed)
  end

  defp count_register_qty({:ok, %RegisterEntry{status: @status_not_found}}, acc) do
    increment_qty(acc, :not_found)
  end

  defp count_register_qty({:ok, %RegisterEntry{status: @status_processed}}, acc) do
    increment_qty(acc, :processed)
  end

  defp count_register_qty({:ok, %RegisterEntry{status: @status_error}}, acc) do
    increment_qty(acc, :errors)
  end

  defp count_register_qty({:error, msg}, acc) do
    acc
    |> increment_qty(:errors)
    |> Map.update!(:errors, &(&1 ++ [put_line(msg, acc.tmp_line)]))
  end

  defp count_register_qty(entries, acc) when is_list(entries) do
    Enum.reduce(entries, acc, &count_register_qty/2)
  end

  defp put_line(msg, line) do
    case String.last(msg) do
      " " -> msg <> "#{line}"
      _ -> msg
    end
  end

  defp increment_qty(%{qty: qty} = data, field) do
    qty =
      qty
      |> Map.update!(field, &(&1 + 1))
      |> Map.update!(:total, &(&1 + 1))

    Map.put(data, :qty, qty)
  end

  def create_register(attrs) do
    %Register{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def update_register(%Register{} = entity, attrs) do
    entity
    |> changeset(attrs)
    |> Repo.update()
  end

  def create_register_entry(attrs) do
    %RegisterEntry{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  defp changeset(%Register{} = entity, attrs) do
    entity
    |> cast(attrs, @required_register_fields ++ @optional_register_fields)
    |> cast_embed(:qty, with: &changeset/2)
    |> validate_required(@required_register_fields)
  end

  defp changeset(%Register.Qty{} = entity, attrs) do
    entity
    |> cast(attrs, @required_qty_fields)
    |> validate_required(@required_qty_fields)
  end

  defp changeset(%RegisterEntry{} = entity, attrs) do
    entity
    |> cast(attrs, @required_register_entry_fields ++ @optional_register_entry_fields)
    |> validate_required(@required_register_entry_fields)
    |> foreign_key_constraint(:register_id)
  end
end
