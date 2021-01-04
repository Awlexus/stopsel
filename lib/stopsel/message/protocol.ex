defprotocol Stopsel.Message.Protocol do
  @moduledoc "Protocol to turn a datastructure into a `Stopsel.Message`"

  @doc "The assigns the message will have"
  @spec assigns(t()) :: Stopsel.Message.assigns()
  def assigns(data)

  @doc "The text content of the datastructure"
  @spec content(t()) :: Stopsel.Message.content()
  def content(data)
end

defimpl Stopsel.Message.Protocol, for: BitString do
  @moduledoc false
  def assigns(_), do: %{}
  def content(string), do: string
end
