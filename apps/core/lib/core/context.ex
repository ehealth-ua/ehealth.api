defmodule Core.Context do
  @moduledoc false

  use Confex, otp_app: :core
  require Logger

  @context_param_name_default "legal_entity_id"

  def get_context_params(client_id, client_type, context_param_name \\ @context_param_name_default) do
    cond do
      client_type in config()[:tokens_types_personal] ->
        %{context_param_name => client_id}

      client_type in config()[:tokens_types_mis] ->
        %{}

      client_type in config()[:tokens_types_admin] ->
        %{}

      client_type in config()[:tokens_types_cabinet] ->
        %{}

      true ->
        Logger.error(fn ->
          Jason.encode!(%{
            "log_type" => "error",
            "message" => "Undefined client type name #{client_type} for context request.",
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

        %{context_param_name => client_id}
    end
  end

  def get_connection_context_params(client_id, client_type, context_param_name \\ @context_param_name_default) do
    cond do
      client_type in config()[:tokens_types_personal] ->
        %{context_param_name => client_id}

      client_type in config()[:tokens_types_mis] ->
        %{context_param_name => client_id}

      client_type in config()[:tokens_types_admin] ->
        %{}

      client_type in config()[:tokens_types_cabinet] ->
        %{}

      true ->
        Logger.error(fn ->
          Jason.encode!(%{
            "log_type" => "error",
            "message" => "Undefined client type name #{client_type} for context request.",
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

        %{context_param_name => client_id}
    end
  end

  def authorize_legal_entity_id(legal_entity_id, client_id, client_type) do
    cond do
      client_type in config()[:tokens_types_personal] and legal_entity_id != client_id ->
        {:error, :forbidden}

      client_type in config()[:tokens_types_personal] ->
        :ok

      client_type in config()[:tokens_types_mis] ->
        :ok

      client_type in config()[:tokens_types_admin] ->
        :ok

      true ->
        Logger.error(fn ->
          Jason.encode!(%{
            "log_type" => "error",
            "message" => "Undefined client type name #{client_type} for context request.",
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

        {:error, :forbidden}
    end
  end
end
