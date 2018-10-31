defmodule Core.Email do
  @moduledoc false

  import Ecto.Changeset
  import EView.Changeset.Validators.Email

  alias Core.Bamboo.Emails.Sender
  alias Core.Email.Schema
  alias Ecto.Changeset

  @man_api Application.get_env(:core, :api_resolvers)[:man]

  def send(%{"id" => man_id, "to" => to} = attrs) do
    with receivers <- String.split(to, ","),
         %Changeset{valid?: true} <- validate_attrs(Map.delete(attrs, "to"), receivers),
         {:ok, body} <- render_template(man_id, attrs) do
      Sender.send_email(receivers, body, attrs["from"], attrs["subject"])
      :ok
    end
  end

  defp render_template(id, data) do
    config = Confex.fetch_env!(:core, :emails)[:default]

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

  defp validate_attrs(attrs, receivers) do
    fields = ~w(data from subject)a
    attrs = Map.put(attrs, "to", Enum.map(receivers, fn receiver -> %{receiver: String.trim(receiver)} end))

    %Schema{}
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> cast_embed(:to, with: &receivers_changeset/2)
    |> validate_email(:from)
    |> validate_not_match(receivers)
  end

  defp receivers_changeset(schema, params) do
    schema
    |> cast(params, [:receiver])
    |> validate_email(:receiver)
  end

  defp validate_not_match(changeset, receivers) do
    validate_change(changeset, :from, fn :from, from ->
      if receivers == [from] do
        [from: "Fields \"#{from}\" and \"#{[from]}\" must be different"]
      else
        []
      end
    end)
  end
end
