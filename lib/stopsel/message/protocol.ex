defprotocol Stopsel.Message.Protocol do
  @spec assigns(t()) :: Stopsel.Message.assigns()
  def assigns(data)

  @spec content(t()) :: Stopsel.Message.content()
  def content(data)
end

defimpl Stopsel.Message.Protocol, for: BitString do
  def assigns(_), do: %{}
  def content(string), do: string
end
