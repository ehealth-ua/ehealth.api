defmodule Ehealth.Web.Router do
  @moduledoc """
  Attention! Ehealth namespace is not a typo! This name because of Plug module name transformation

  The router provides a set of macros for generating routes
  that dispatch to specific controllers and actions.
  Those macros are named after HTTP verbs.

  More info at: https://hexdocs.pm/phoenix/Phoenix.Router.html
  """
  use EHealth.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :put_secure_browser_headers

    # Uncomment to enable versioning of your API
    # plug Multiverse, gates: [
    #   "2016-07-31": EHealth.Web.InitialGate
    # ]

    # You can allow JSONP requests by uncommenting this line:
    # plug :allow_jsonp
  end

  scope "/api", EHealth.Web do
    pipe_through :api

    put "/legal_entities", LegalEntityController, :create_or_update
    post "/employee_requests", EmployeeRequestController, :create
  end
end
