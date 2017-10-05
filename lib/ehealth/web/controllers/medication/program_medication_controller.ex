defmodule EHealth.Web.ProgramMedicationController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.PRM.Medications.API, as: MedicationsAPI
  alias EHealth.PRM.Medications.Program.Schema, as: ProgramMedication

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    program_medications = MedicationsAPI.list_program_medications(params)
    render(conn, "index.json", program_medications: program_medications)
  end

  def create(conn, params) do
    with {:ok, %ProgramMedication{} = program} <- MedicationsAPI.create_program_medication(params, conn.req_headers) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", program_medication_path(conn, :show, program))
      |> render("show.json", program_medication: program)
    end
  end

  def show(conn, %{"id" => id}) do
    program = MedicationsAPI.get_program_medication!(id, :preload)
    render(conn, "show.json", program_medication: program)
  end

  def update(conn, %{"id" => id} = params) do
    program = MedicationsAPI.get_program_medication!(id)

    with {:ok, %ProgramMedication{} = program} <- MedicationsAPI.update_program_medication(
      program,
      params,
      conn.req_headers
    ) do
      render(conn, "show.json", program_medication: program)
    end
  end
end
