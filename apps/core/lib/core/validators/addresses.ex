defmodule Core.Validators.Addresses do
  @moduledoc """
  KVED codes validator
  """

  alias Core.ValidationError
  alias Core.Validators.Error

  @rpc_worker Application.get_env(:core, :rpc_worker)

  def validate(addresses) when is_list(addresses), do: validate_addresses_values(addresses)

  def validate(address) when is_map(address), do: validate_addresses_values(address)

  def validate(addresses, required_type) when is_list(addresses) do
    with :ok <- validate_addresses_type(addresses, required_type) do
      validate_addresses_values(addresses)
    end
  end

  defp validate_addresses_type(addresses, required_type) do
    addresses_count =
      addresses
      |> Enum.filter(fn x -> Map.get(x, "type") == required_type end)
      |> length()

    case addresses_count do
      0 ->
        Error.dump(%ValidationError{
          description: "Addresses with type #{required_type} should be present",
          path: "$.addresses"
        })

      1 ->
        :ok

      n ->
        Error.dump(%ValidationError{
          description: "Single address of type '#{required_type}' is required, got: #{n}",
          path: "$.addresses"
        })
    end
  end

  defp validate_addresses_values(addresses) do
    case @rpc_worker.run("uaddresses_api", Uaddresses.Rpc, :validate, [addresses]) do
      :ok ->
        :ok

      {:error, %{invalid: errors}} ->
        Error.dump(
          Enum.map(errors, fn %{rules: rules, entry: entry} ->
            %ValidationError{
              description: rules |> hd |> Map.get(:description),
              path: entry
            }
          end)
        )

      _ ->
        Error.dump("Invalid params")
    end
  end
end
