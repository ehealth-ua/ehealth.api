defmodule Core.Ecto.DateRange do
  @moduledoc false

  @behaviour Ecto.Type

  defstruct [:lower, :upper, lower_inclusive: true, upper_inclusive: true]

  @type t :: %__MODULE__{
          lower: boundary_t(),
          upper: boundary_t(),
          lower_inclusive: boolean(),
          upper_inclusive: boolean()
        }

  @type boundary_t :: Date.t() | nil

  @open_boundary ".."
  @interval_designator "/"

  @spec new(boundary_t(), boundary_t(), Keyword.t()) :: {:ok, t} | {:error, atom}
  def new(lower, upper, opts \\ []) do
    with {:ok, lower} <- cast_boundary(lower),
         {:ok, upper} <- cast_boundary(upper),
         :ok <- check_boundaries(lower, upper) do
      fields =
        opts
        |> Keyword.take([:lower_inclusive, :upper_inclusive])
        |> Keyword.merge(lower: lower, upper: upper)

      {:ok, struct(__MODULE__, fields)}
    end
  end

  defp cast_boundary(%Date{} = boundary), do: {:ok, boundary}
  defp cast_boundary(nil), do: {:ok, nil}
  defp cast_boundary(_), do: {:error, :invalid_boundaries}

  def check_boundaries(%Date{calendar: calendar} = lower, %Date{calendar: calendar} = upper) do
    case Date.compare(lower, upper) do
      :gt -> {:error, :invalid_boundaries}
      _ -> :ok
    end
  end

  def check_boundaries(%Date{}, %Date{}), do: {:error, :calendars_mismatch}
  def check_boundaries(nil, nil), do: {:error, :invalid_boundaries}
  def check_boundaries(_, _), do: :ok

  @spec from_iso8601(String.t()) :: {:ok, t} | {:error, atom}
  def from_iso8601(string) do
    with {:ok, lower, upper} <- raw_from_iso8601(string),
         {:ok, lower} <- boundary_from_string(lower),
         {:ok, upper} <- boundary_from_string(upper) do
      new(lower, upper)
    end
  end

  defp raw_from_iso8601(<<lower::binary-size(10), ?/, upper::binary-size(10)>>),
    do: {:ok, lower, upper}

  defp raw_from_iso8601(<<lower::binary-size(2), ?/, upper::binary-size(10)>>),
    do: {:ok, lower, upper}

  defp raw_from_iso8601(<<lower::binary-size(10), ?/, upper::binary-size(2)>>),
    do: {:ok, lower, upper}

  defp raw_from_iso8601(_), do: {:error, :invalid_format}

  defp boundary_from_string(@open_boundary), do: {:ok, nil}
  defp boundary_from_string(string), do: Date.from_iso8601(string)

  @spec from_iso8601!(String.t()) :: t
  def from_iso8601!(string) do
    case from_iso8601(string) do
      {:ok, value} ->
        value

      {:error, reason} ->
        raise ArgumentError,
              "cannot parse #{inspect(string)} as date interval, reason: #{inspect(reason)}"
    end
  end

  @spec to_iso8601(t, :extended | :basic) :: String.t()
  def to_iso8601(%__MODULE__{lower: lower, upper: upper}, format \\ :extended) do
    boundary_to_string(lower, format) <> @interval_designator <> boundary_to_string(upper, format)
  end

  defp boundary_to_string(nil, _), do: @open_boundary
  defp boundary_to_string(date, format), do: Date.to_iso8601(date, format)

  @impl Ecto.Type
  def type, do: :daterange

  @impl Ecto.Type
  def cast(term)
  def cast(%__MODULE__{} = range), do: {:ok, range}
  def cast(_), do: :error

  @impl Ecto.Type
  def load(term)

  def load(%Postgrex.Range{
        lower: lower,
        upper: upper,
        lower_inclusive: lower_inclusive,
        upper_inclusive: upper_inclusive
      }) do
    with {:ok, lower} <- db_to_date(lower),
         {:ok, upper} <- db_to_date(upper) do
      {:ok,
       %__MODULE__{
         lower: lower,
         upper: upper,
         lower_inclusive: lower_inclusive,
         upper_inclusive: upper_inclusive
       }}
    else
      _ -> :error
    end
  end

  def load(_), do: :error

  @impl Ecto.Type
  def dump(term)

  def dump(%__MODULE__{
        lower: lower,
        upper: upper,
        lower_inclusive: lower_inclusive,
        upper_inclusive: upper_inclusive
      }) do
    {:ok,
     %Postgrex.Range{
       lower: date_to_db(lower),
       upper: date_to_db(upper),
       lower_inclusive: lower_inclusive,
       upper_inclusive: upper_inclusive
     }}
  end

  def dump(_), do: :error

  defp db_to_date(nil), do: {:ok, nil}
  defp db_to_date(term), do: Date.from_erl(term)

  defp date_to_db(nil), do: nil
  defp date_to_db(date), do: Date.to_erl(date)
end
