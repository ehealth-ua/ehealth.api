defmodule EHealth.Registers.API do
  @moduledoc false

  use EHealth.Search, EHealth.Repo

  import Ecto.Changeset

  alias EHealth.Repo
  alias EHealth.API.{MPI, OPS}
  alias EHealth.Ecto.Base64
  alias EHealth.Validators.JsonSchema
  alias EHealth.Registers.{Register, RegisterEntry, SearchRegisters, SearchRegisterEntries}

  @status_matched RegisterEntry.status(:matched)
  @status_not_found RegisterEntry.status(:not_found)
  @status_processing RegisterEntry.status(:processing)
  @status_processed Register.status(:processed)

  @required_register_fields ~w(
    file_name
    type
    status
    inserted_by
  )a
  @optional_register_fields ~w(
    errors
    updated_by
  )a

  @required_qty_fields ~w(
    total
    errors
    not_found
    processing
  )a

  @required_register_entry_fields ~w(
    status
    inserted_by
  )a
  @optional_register_entry_fields ~w(
    tax_id
    national_id
    passport
    birth_certificate
    temporary_certificate
    person_id
    updated_by
  )a

  @csv_headers ~w(
    tax_id
    passport
    national_id
    birth_certificate
    temporary_certificate
  )

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

    q = where(entity, ^params)

    Enum.reduce(changes, q, fn {key, val}, query ->
      case key do
        :inserted_at_from -> where(query, [r], r.inserted_at >= ^date_to_datetime(val))
        :inserted_at_to -> where(query, [r], r.inserted_at <= ^date_to_datetime(val))
        _ -> query
      end
    end)
  end

  def get_search_query(entity, changes), do: super(entity, changes)

  defp date_to_datetime(date) do
    date
    |> Date.to_string()
    |> Timex.parse!("{YYYY}-{0M}-{0D}")
  end

  def process_register_file(attrs, author_id) do
    with %Ecto.Changeset{valid?: true} <- cast({%{}, %{file: Base64}}, attrs, [:file]),
         :ok <- JsonSchema.validate(:registers, attrs),
         register_data <- prepare_register_data(attrs, author_id),
         {:ok, %Register{} = register} <- create_register(register_data),
         reason_desc <- attrs["reason_description"],
         {:ok, processed_entries} <- batch_create_register_entries(register, attrs, reason_desc),
         register_update_data <- prepare_register_update_data(processed_entries),
         {:ok, register} <- update_register(register, register_update_data) do
      {:ok, register}
    end
  end

  defp prepare_register_data(attrs, author_id) do
    Map.merge(attrs, %{
      "status" => Register.status(:new),
      "inserted_by" => author_id
    })
  end

  def batch_create_register_entries(register, %{"file" => base64file}, reason_desc) do
    with parsed_csv <- parse_csv(base64file),
         {:ok, headers} <- fetch_headers(parsed_csv),
         true <- valid_csv_headers?(headers) do
      entries =
        parsed_csv
        |> Enum.map(&Task.async(fn -> process_register_entry(&1, register, reason_desc) end))
        |> Enum.map(&Task.await/1)

      {:ok, entries}
    end
  end

  defp parse_csv(file) do
    file
    |> Base.decode64!()
    |> String.split("\n")
    |> CSV.decode(headers: true)
  end

  defp fetch_headers(csv) do
    case Enum.take(csv, 1) do
      [ok: headers] -> {:ok, headers}
      _ -> {:error, {:"422", "Invalid CSV headers"}}
    end
  end

  defp valid_csv_headers?(headers) when map_size(headers) == 5 do
    case Enum.all?(headers, fn {key, _} -> key in @csv_headers end) do
      true -> true
      _ -> {:error, {:"422", "Invalid CSV headers"}}
    end
  end

  defp valid_csv_headers?(_) do
    {:error, {:"422", "Invalid CSV headers"}}
  end

  defp process_register_entry({:ok, entry_data}, register, reason_desc) do
    mpi_response = entry_data |> prepare_person_search_params() |> MPI.admin_search()

    entry_data
    |> Map.merge(%{
      "register_id" => register.id,
      "inserted_by" => register.inserted_by
    })
    |> set_entry_status(mpi_response)
    |> maybe_terminate_person_declaration(register.type, reason_desc)
    |> create_register_entry()
  end

  defp process_register_entry(err, _, _), do: err

  def prepare_person_search_params(params) do
    search_fields = ~w(tax_id national_id passport birth_certificate temporary_certificate)

    Enum.reduce_while(search_fields, %{}, fn search_key, acc ->
      case params[search_key] do
        "" -> {:cont, acc}
        search_value when byte_size(search_value) > 0 -> {:halt, %{search_key => search_value}}
      end
    end)
  end

  defp set_entry_status(entry_data, {:ok, %{"data" => persons}}) when is_list(persons) and length(persons) > 0 do
    Map.merge(entry_data, %{
      "person_id" => hd(persons)["id"],
      "status" => @status_matched
    })
  end

  defp set_entry_status(entry_data, {:ok, %{"data" => []}}) do
    Map.put(entry_data, "status", @status_not_found)
  end

  defp set_entry_status(entry_data, _) do
    Map.put(entry_data, "status", @status_processing)
  end

  defp maybe_terminate_person_declaration(%{"status" => @status_matched} = entry_data, type, reason_desc) do
    case OPS.terminate_person_declarations(
           entry_data["person_id"],
           entry_data["inserted_by"],
           "auto_" <> type,
           reason_desc
         ) do
      {:ok, _} -> entry_data
      _ -> Map.put(entry_data, "status", @status_processing)
    end
  end

  defp maybe_terminate_person_declaration(entry_data, _type, _reason_desc), do: entry_data

  defp prepare_register_update_data(processed_entries) do
    acc = %{
      status: @status_processed,
      qty: %{total: 0, not_found: 0, processing: 0, errors: 0},
      errors: []
    }

    Enum.reduce(processed_entries, acc, fn entry, acc ->
      case entry do
        {:ok, %RegisterEntry{status: @status_matched}} ->
          Map.put(acc, :qty, Map.update!(acc.qty, :total, &(&1 + 1)))

        {:ok, %RegisterEntry{status: @status_not_found}} ->
          increment_qty(acc, :not_found)

        {:ok, %RegisterEntry{status: @status_processing}} ->
          acc
          |> increment_qty(:processing)
          |> Map.put(:status, @status_processing)

        {:error, msg} ->
          acc
          |> increment_qty(:errors)
          |> Map.update!(:errors, &(&1 ++ [msg]))
      end
    end)
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
  end
end
