defmodule Casher.Router do
  @moduledoc false

  use Casher.Web, :router

  require Logger

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", Casher.Web do
    pipe_through(:api)

    get("/person_data", PersonDataController, :get_person_data)
    patch("/person_data", PersonDataController, :update_person_data)
  end
end
