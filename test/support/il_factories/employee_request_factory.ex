defmodule EHealth.ILFactories.EmployeeRequestFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID
      alias EHealth.Employee.Request

      def employee_request_factory do
        %Request{
          status: Request.status(:new),
          employee_id: Ecto.UUID.generate(),
          data: %{}
        }
      end
    end
  end
end
