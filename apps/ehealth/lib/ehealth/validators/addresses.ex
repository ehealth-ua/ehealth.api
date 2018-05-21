defmodule EHealth.Validators.Addresses do
  @moduledoc """
  KVED codes validator
  """
  @uaddresses_api Application.get_env(:ehealth, :api_resolvers)[:uaddresses]

  def validate(addresses, headers) when is_list(addresses), do: validate_addresses_values(addresses, headers)

  def validate(addresses, required_type, headers) when is_list(addresses) do
    with :ok <- validate_addresses_type(addresses, required_type) do
      validate_addresses_values(addresses, headers)
    end
  end

  defp validate_addresses_type(addresses, required_type) do
    addresses_count =
      addresses
      |> Enum.filter(fn x -> Map.get(x, "type") == required_type end)
      |> length()

    case addresses_count do
      1 ->
        :ok

      _ ->
        {:error,
         [
           {%{description: "Single address of type '#{required_type}' is required", params: [], rule: :invalid},
            "$.addresses"}
         ]}
    end
  end

  defp validate_addresses_values(addresses, headers) do
    case @uaddresses_api.validate_addresses(addresses, headers) do
      {:ok, %{"data" => _}} ->
        :ok

      {:error, %{"error" => %{"invalid" => errors}}} ->
        {:error,
         Enum.map(errors, fn error ->
           {hd(error["rules"]), error["entry"]}
         end)}
    end
  end
end
