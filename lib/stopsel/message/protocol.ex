defprotocol Stopsel.Message.Protocol do
  @moduledoc "Protocol to turn a data structure into a `Stopsel.Message`."

  @doc "Returns the assigns for the message."
  @spec assigns(t()) :: Stopsel.Message.assigns()
  def assigns(data)

  @doc "Returns the text content for the message."
  @spec content(t()) :: Stopsel.Message.content()
  def content(data)

  @doc "Returns parameters for the message"
  @spec params(t()) :: Stopsel.Message.params()
  def params(data)
end

defimpl Stopsel.Message.Protocol, for: BitString do
  @moduledoc false
  def assigns(_), do: %{}
  def content(string), do: string
  def params(_), do: %{}
end
