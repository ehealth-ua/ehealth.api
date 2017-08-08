defmodule EHealth.DeclarationRequest.API.Helpers do
  @moduledoc false

  def request_end_date(today, expiration, birth_date, adult_age) do
    birth_date = Date.from_iso8601!(birth_date)

    normal_expiration_date   = Timex.shift(today, expiration)
    adjusted_expiration_date = Timex.shift(birth_date, years: adult_age, days: -1)

    if Timex.diff(today, birth_date, :years) >= adult_age do
      normal_expiration_date
    else
      case Timex.compare(normal_expiration_date, adjusted_expiration_date) do
        -1 -> normal_expiration_date
         0 -> normal_expiration_date
         1 -> adjusted_expiration_date
      end
    end
  end

  def gather_documents_list(person) do
    p_docs = if person["tax_id"], do: ["person.SSN"], else: []
    p_docs = p_docs ++ Enum.map(person["documents"], &"person.#{&1["type"]}")

    person["confidant_person"]
    |> Enum.with_index
    |> Enum.reduce(p_docs, fn {cp, idx}, acc ->
        tax_id = if cp["tax_id"], do: ["confidant_person.#{idx}.#{cp["relation_type"]}.SSN"], else: []

        person_docs = Enum.map cp["documents_person"], fn doc ->
          "confidant_person.#{idx}.#{cp["relation_type"]}.#{doc["type"]}"
        end

        relationship_docs = Enum.map cp["documents_relationship"], fn doc ->
          "confidant_person.#{idx}.#{cp["relation_type"]}.RELATIONSHIP.#{doc["type"]}"
        end

        tax_id ++ person_docs ++ relationship_docs ++ acc
       end)
  end
end
