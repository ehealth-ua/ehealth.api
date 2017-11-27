defmodule EHealth.Web.ProgramMedicationController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.Medications
  alias EHealth.Medications.Program, as: ProgramMedication

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- Medications.list_program_medications(params) do
      render(conn, "index.json", program_medications: paging.entries, paging: paging)
    end
  end

  def create(conn, params) do
    with {:ok, %ProgramMedication{} = program} <- Medications.create_program_medication(params, conn.req_headers) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", program_medication_path(conn, :show, program))
      |> render("show.json", program_medication: program)
    end
  end

  def show(conn, %{"id" => id}) do
    program = Medications.get_program_medication!(id, :preload)
    render(conn, "show.json", program_medication: program)
  end

  def update(conn, %{"id" => id} = params) do
    program = Medications.get_program_medication!(id)

    with {:ok, %ProgramMedication{} = program} <- Medications.update_program_medication(
      program,
      params,
      conn.req_headers
    ) do
      render(conn, "show.json", program_medication: program)
    end
  end
end
