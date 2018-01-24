defmodule EHealth.DeclarationRequest.API.Helpers do
  @moduledoc false

  def request_end_date(today, expiration, birth_date, adult_age) do
    birth_date = Date.from_iso8601!(birth_date)

    normal_expiration_date = Timex.shift(today, expiration)
    adjusted_expiration_date = Timex.shift(birth_date, years: adult_age, days: -1)

    if Timex.diff(today, birth_date, :years) >= adult_age do
      normal_expiration_date
    else
      case Timex.compare(normal_expiration_date, adjusted_expiration_date) do
        1 -> adjusted_expiration_date
        x when x < 1 -> normal_expiration_date
      end
    end
  end

  def gather_documents_list(person) do
    person_documents =
      if person["tax_id"], do: ["person.SSN", "person.DECLARATION_FORM"], else: ["person.DECLARATION_FORM"]

    person_documents = person_documents ++ Enum.map(person["documents"], &"person.#{&1["type"]}")

    has_birth_certificate =
      Enum.reduce_while(person["documents"], false, fn document, acc ->
        if document["type"] == "BIRTH_CERTIFICATE", do: {:halt, true}, else: {:cont, acc}
      end)

    person
    |> Map.get("confidant_person", [])
    |> Enum.with_index()
    |> Enum.reduce({person_documents, has_birth_certificate}, &gather_confidant_documents/2)
    |> elem(0)
    |> Enum.uniq()
  end

  defp gather_confidant_documents({cp, idx}, {documents, has_birth_certificate}) do
    confidant_documents =
      cp["documents_relationship"]
      |> Enum.reduce([], fn doc, acc ->
        # skip BIRTH_CERTIFICATE if it was already added in person documents
        if doc["type"] == "BIRTH_CERTIFICATE" && has_birth_certificate do
          acc
        else
          ["confidant_person.#{idx}.#{cp["relation_type"]}.RELATIONSHIP.#{doc["type"]}" | acc]
        end
      end)
      |> Enum.reverse()
      |> Kernel.++(documents)

    {confidant_documents, has_birth_certificate}
  end
end
