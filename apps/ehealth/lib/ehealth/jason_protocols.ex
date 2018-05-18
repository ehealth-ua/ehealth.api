require Protocol

Protocol.derive(Jason.Encoder, HTTPoison.Error)

defimpl Jason.Encoder, for: EHealth.Registers.Register.Qty do
  alias Jason.Encode

  def encode(value, opts) do
    Encode.map(Map.take(value, EHealth.Registers.Register.Qty.__schema__(:fields)), opts)
  end
end

defimpl Jason.Encoder, for: EHealth.MedicationRequestRequest.EmbeddedData do
  alias Jason.Encode

  def encode(value, opts) do
    Encode.map(Map.take(value, EHealth.MedicationRequestRequest.EmbeddedData.__schema__(:fields)), opts)
  end
end
