defmodule EHealth.Web do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller, namespace: EHealth.Web
      import Plug.Conn
      import EHealth.Proxy
      import EHealthWeb.Router.Helpers
      import EHealth.Utils.Connection
    end
  end

  def view do
    quote do
      use Phoenix.View, root: ""
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import EHealth.Utils.Connection
      import EHealth.Plugs.Headers
      import EHealth.Plugs.ClientContext
    end
  end

  def plugs do
    quote do
      import EHealth.Proxy
      import EHealth.Utils.Connection, only: [get_header_name: 1, get_client_id: 1]
      import Plug.Conn, only: [put_status: 2, halt: 1, get_req_header: 2, assign: 3]
      import Phoenix.Controller, only: [render: 4, render: 3]
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
