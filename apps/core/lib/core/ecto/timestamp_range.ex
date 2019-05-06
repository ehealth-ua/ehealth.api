defmodule Core.Ecto.TimestampRange do
  @moduledoc false

  @behaviour Ecto.Type

  defstruct [:lower, :upper, lower_inclusive: true, upper_inclusive: true]

  @type t :: %__MODULE__{
          lower: boundary_t(),
          upper: boundary_t(),
          lower_inclusive: boolean(),
          upper_inclusive: boolean()
        }

  @type boundary_t :: DateTime.t() | nil

  @match_regex ~r{^([^/]+)/([^/]+)$}
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

  defp cast_boundary(%DateTime{} = boundary), do: {:ok, boundary}
  defp cast_boundary(nil), do: {:ok, nil}
  defp cast_boundary(_), do: {:error, :invalid_boundaries}

  def check_boundaries(%DateTime{calendar: calendar} = lower, %DateTime{calendar: calendar} = upper) do
    case DateTime.compare(lower, upper) do
      :gt -> {:error, :invalid_boundaries}
      _ -> :ok
    end
  end

  def check_boundaries(%DateTime{}, %DateTime{}), do: {:error, :calendars_mismatch}
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

  defp raw_from_iso8601(string) do
    case Regex.run(@match_regex, string, capture: :all_but_first) do
      [lower, upper] -> {:ok, lower, upper}
      _ -> {:error, :invalid_format}
    end
  end

  defp boundary_from_string(@open_boundary), do: {:ok, nil}

  defp boundary_from_string(string) do
    with {:ok, datetime, _} <- DateTime.from_iso8601(string) do
      {:ok, datetime}
    end
  end

  @spec from_iso8601!(String.t()) :: t
  def from_iso8601!(string) do
    case from_iso8601(string) do
      {:ok, value} ->
        value

      {:error, reason} ->
        raise ArgumentError,
              "cannot parse #{inspect(string)} as datetime interval, reason: #{inspect(reason)}"
    end
  end

  @spec to_iso8601(t, :extended | :basic) :: String.t()
  def to_iso8601(%__MODULE__{lower: lower, upper: upper}, format \\ :extended) do
    boundary_to_string(lower, format) <> @interval_designator <> boundary_to_string(upper, format)
  end

  defp boundary_to_string(nil, _), do: @open_boundary
  defp boundary_to_string(datetime, format), do: DateTime.to_iso8601(datetime, format)

  @impl Ecto.Type
  def type, do: :tsrange

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
    {:ok,
     %__MODULE__{
       lower: lower,
       upper: upper,
       lower_inclusive: lower_inclusive,
       upper_inclusive: upper_inclusive
     }}
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
       lower: lower,
       upper: upper,
       lower_inclusive: lower_inclusive,
       upper_inclusive: upper_inclusive
     }}
  end

  def dump(_), do: :error
end
