defmodule Date.Interval do
  @moduledoc """
  The date interval implementation that follows to ISO 8601-2/EDTF.
  """

  defstruct [:first, :last]

  @type t :: %__MODULE__{first: Date.t() | nil, last: Date.t() | nil}

  @spec new(Date.t() | nil, Date.t() | nil) :: {:ok, t} | {:error, atom}
  def new(first, last)

  def new(%Date{calendar: calendar} = first, %Date{calendar: calendar} = last) do
    case Date.compare(first, last) do
      :gt -> {:error, :invalid_boundaries}
      _ -> {:ok, %__MODULE__{first: first, last: last}}
    end
  end

  def new(%Date{}, %Date{}), do: {:error, :calendars_mismatch}

  def new(%Date{} = first, nil), do: {:ok, %__MODULE__{first: first, last: nil}}

  def new(nil, %Date{} = last), do: {:ok, %__MODULE__{first: nil, last: last}}

  def new(_, _), do: {:error, :invalid_boundaries}

  @spec from_edtf(String.t()) :: {:ok, t} | {:error, atom}
  def from_edtf(string) do
    with {:ok, first, last} <- raw_from_edtf(string),
         {:ok, first} <- boundary_from_string(first),
         {:ok, last} <- boundary_from_string(last) do
      new(first, last)
    end
  end

  defp raw_from_edtf(<<first::binary-size(10), ?/, last::binary-size(10)>>), do: {:ok, first, last}
  defp raw_from_edtf(<<first::binary-size(10), ?/, ?., ?.>>), do: {:ok, first, nil}
  defp raw_from_edtf(<<?., ?., ?/, last::binary-size(10)>>), do: {:ok, nil, last}
  defp raw_from_edtf(_), do: {:error, :invalid_format}

  @spec from_edtf!(String.t()) :: t
  def from_edtf!(string) do
    case from_edtf(string) do
      {:ok, value} ->
        value

      {:error, reason} ->
        raise ArgumentError,
              "cannot parse #{inspect(string)} as date interval, reason: #{inspect(reason)}"
    end
  end

  defp boundary_from_string(nil), do: {:ok, nil}
  defp boundary_from_string(date), do: Date.from_iso8601(date)

  @spec to_edtf(Date.Interval.t()) :: String.t()
  def to_edtf(%{first: first, last: last}) do
    for(boundary <- [first, last], do: boundary_to_string(boundary)) |> Enum.join("/")
  end

  defp boundary_to_string(nil), do: ".."
  defp boundary_to_string(date), do: Date.to_iso8601(date)

  defimpl String.Chars do
    defdelegate to_string(interval), to: Date.Interval, as: :to_edtf
  end

  defimpl Inspect do
    def inspect(%Date.Interval{first: first, last: last}, _) do
      "#DateInterval<" <> inspect(first) <> ", " <> inspect(last) <> ">"
    end
  end
end
