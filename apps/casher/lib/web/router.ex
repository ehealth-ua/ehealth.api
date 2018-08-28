defmodule Casher.Router do
  @moduledoc false

  use Casher.Web, :router
  use Plug.ErrorHandler

  alias Plug.LoggerJSON

  require Logger

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", Casher.Web do
    pipe_through(:api)

    get("/person_data", PersonDataController, :get_person_data)
    patch("/person_data", PersonDataController, :update_person_data)
  end

  @spec handle_errors(Plug.Conn.t(), map) :: Plug.Conn.t()
  defp handle_errors(%Plug.Conn{status: 500} = conn, %{kind: kind, reason: reason, stack: stacktrace}) do
    LoggerJSON.log_error(kind, reason, stacktrace)

    Logger.log(:info, fn ->
      Jason.encode!(%{
        "log_type" => "debug",
        "request_params" => conn.params,
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    send_resp(conn, 500, Jason.encode!(%{errors: %{detail: "Internal server error"}}))
  end

  defp handle_errors(_, _), do: nil
end
