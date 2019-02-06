defmodule Core.Users.Validator do
  @moduledoc false

  def user_has_role(roles, role, reason \\ "FORBIDDEN") when is_list(roles) do
    case Enum.find(roles, &(Map.get(&1, "role_name") == role)) do
      nil -> {:error, {:forbidden, reason}}
      _ -> :ok
    end
  end
end
