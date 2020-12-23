defmodule Stopsel.Message do
  defstruct assigns: %{}, params: %{}, halted?: false, message: nil, status: nil

  @type status :: :no_route | :handled | :halted
  @type t :: %__MODULE__{
          assigns: map(),
          params: map(),
          halted?: boolean(),
          message: String.t(),
          status: status()
        }

  def assign(%__MODULE__{assigns: assigns} = message, key, value) do
    %{message | assigns: Map.put(assigns, key, value)}
  end

  def assign(message, nil), do: message

  def assign(%__MODULE__{assigns: assigns} = message, new_assigns) do
    %{message | assigns: Map.merge(assigns, Map.new(new_assigns))}
  end

  def halt(%__MODULE__{} = message) do
    %{message | halted?: true}
  end

  def put_param(%__MODULE__{params: params} = message, key, value) do
    %{message | params: Map.put(params, key, value)}
  end

  def put_params(%__MODULE__{params: old_params} = message, new_params) do
    %{message | params: Map.merge(old_params, new_params)}
  end

  @doc false
  def capture_rest(message, drop_words) do
    rest =
      message.message
      |> String.split(~r/\s+/, trim: true, parts: drop_words + 1)
      |> List.last()

    %{message | rest: rest}
  end
end

defprotocol Stopsel.Message.Protocol do
  @doc "Converts the data to a stopsel message"
  @spec to_message(t()) :: Stopsel.Message.t()
  def to_message(data)
end

defimpl Stopsel.Message.Protocol, for: Stopsel.Message do
  def to_message(message), do: message
end
