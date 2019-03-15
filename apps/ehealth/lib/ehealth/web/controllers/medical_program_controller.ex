defmodule EHealth.Web.MedicalProgramController do
  @moduledoc false

  use EHealth.Web, :controller
  alias Core.MedicalPrograms
  alias Core.Validators.JsonSchema
  alias Scrivener.Page
  require Logger

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    with %Page{} = paging <- MedicalPrograms.list(params) do
      render(conn, "index.json", medical_programs: paging.entries, paging: paging)
    end
  end

  def create(%Plug.Conn{req_headers: headers} = conn, params) do
    consumer_id = get_consumer_id(headers)

    with :ok <- JsonSchema.validate(:medical_program, params),
         {:ok, medical_program} <- MedicalPrograms.create(params, consumer_id) do
      conn
      |> put_status(:created)
      |> render("show.json", medical_program: medical_program)
    end
  end

  def show(conn, %{"id" => id}) do
    with medical_program <- MedicalPrograms.get_by_id!(id) do
      render(conn, "show.json", medical_program: medical_program)
    end
  end

  def deactivate(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    consumer_id = get_consumer_id(headers)
    medical_program = MedicalPrograms.get_by_id!(id)

    with {:ok, medical_program} <- MedicalPrograms.deactivate(medical_program, consumer_id) do
      render(conn, "show.json", medical_program: medical_program)
    end
  end
end
