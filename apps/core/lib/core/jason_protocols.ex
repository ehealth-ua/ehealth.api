require Protocol

Protocol.derive(Jason.Encoder, HTTPoison.Error)

defimpl Jason.Encoder, for: Core.Registers.Register.Qty do
  alias Jason.Encode

  def encode(value, opts) do
    Encode.map(Map.take(value, Core.Registers.Register.Qty.__schema__(:fields)), opts)
  end
end

defimpl Jason.Encoder, for: Core.MedicationRequestRequest.EmbeddedData do
  alias Jason.Encode

  def encode(value, opts) do
    Encode.map(Map.take(value, Core.MedicationRequestRequest.EmbeddedData.__schema__(:fields)), opts)
  end
end
