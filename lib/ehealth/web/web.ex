defmodule EHealth.Web do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller, namespace: EHealth.Web
      import Plug.Conn
      import EHealth.Proxy
      import Ehealth.Web.Router.Helpers
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
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
