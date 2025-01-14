defimpl Jason.Encoder, for: Decimal do
  def encode(decimal, opts) do
    Decimal.to_string(decimal)
    |> Jason.Encode.string(opts)
  end
end
