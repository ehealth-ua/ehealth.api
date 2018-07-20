defmodule EHealth.Email do
  @moduledoc false

  import Ecto.Changeset
  import EView.Changeset.Validators.Email

  alias Ecto.Changeset
  alias EHealth.Bamboo.Emails.Sender
  alias EHealth.Email.Schema

  @man_api Application.get_env(:ehealth, :api_resolvers)[:man]

  def send(%{"id" => man_id} = attrs) do
    with %Changeset{valid?: true} <- validate_attrs(attrs),
         {:ok, body} <- render_template(man_id, attrs) do
      Sender.send_email(attrs["to"], body, attrs["from"], attrs["subject"])
      :ok
    end
  end

  defp render_template(id, data) do
    config = Confex.fetch_env!(:ehealth, :emails)[:default]

    data =
      %{
        "format" => config.format,
        "locale" => config.locale
      }
      |> Map.merge(data)
      |> Map.delete("id")

    case @man_api.render_template(id, data, []) do
      {:ok, body} -> {:ok, body}
      {:error, err} -> {:error, {:bad_request, "Cannot render email template with: \"#{inspect(err)}\""}}
    end
  end

  defp validate_attrs(attrs) do
    fields = Schema.__schema__(:fields)

    %Schema{}
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> validate_email(:from)
    |> validate_email(:to)
    |> validate_not_match(:from, :to)
  end

  def validate_not_match(changeset, field1, field2) do
    validate_change(changeset, field1, fn field1, field1_value ->
      case field1_value == get_change(changeset, field2) do
        true -> ["#{field1}": "Fields \"#{field1}\" and \"#{field2}\" must be different"]
        _ -> []
      end
    end)
  end
end
