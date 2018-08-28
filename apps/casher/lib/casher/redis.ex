defmodule Casher.Redis do
  @moduledoc """
  Provides convenient access to Redis using Redix under the hood
  Serializes and stores data using Erlang `term_to_binary`
  """

  alias Core.Log

  @spec get(binary) :: {:ok, term} | {:error, binary}
  def get(key) when is_binary(key) do
    with {:ok, encoded_value} <- command(["GET", key]) do
      if encoded_value == nil do
        {:error, :not_found}
      else
        {:ok, decode(encoded_value)}
      end
    else
      {:error, reason} = err ->
        Log.error("[#{__MODULE__}] Fail to get value by key (#{key}) with error #{inspect(reason)}")
        err
    end
  end

  @spec set(binary, term) :: :ok | {:error, binary}
  def set(key, value) when is_binary(key) and value != nil,
    do: do_set(["SET", key, encode(value)])

  @spec setex(binary, term, pos_integer) :: :ok | {:error, binary}
  def setex(key, ttl_seconds, value) when is_binary(key) and is_integer(ttl_seconds) and value != nil,
    do: do_set(["SETEX", key, ttl_seconds, encode(value)])

  @spec do_set(list) :: :ok | {:error, binary}
  defp do_set(params) do
    case command(params) do
      {:ok, _} ->
        :ok

      {:error, reason} = err ->
        Log.error("[#{__MODULE__}] Fail to set with params #{inspect(params)} with error #{inspect(reason)}")
        err
    end
  end

  @spec del(binary) :: {:ok, non_neg_integer} | {:error, binary}
  def del(key) when is_binary(key) do
    case command(["DEL", key]) do
      {:ok, n} when n >= 1 -> {:ok, n}
      err -> err
    end
  end

  @spec flushdb :: :ok | {:error, binary}
  def flushdb do
    case command(["FLUSHDB"]) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec encode(term) :: term
  defp encode(value), do: :erlang.term_to_binary(value)

  @spec decode(term) :: term
  defp decode(value), do: :erlang.binary_to_term(value)

  @spec command(list) :: {:ok, term} | {:error, term}
  defp command(command) when is_list(command) do
    pool_size = Confex.fetch_env!(:casher, :redis_pool_size)
    connection_index = rem(System.unique_integer([:positive]), pool_size)

    Redix.command(:"redis_#{connection_index}", command)
  end
end
