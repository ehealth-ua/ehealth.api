defmodule EHealth.Employee.UserCreateRequest do
  @moduledoc false

  use Ecto.Schema

  schema "user_create_request" do
    field :password, :string
  end
end
