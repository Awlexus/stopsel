defmodule Stopsel.Message do
  defstruct assigns: %{}, params: %{}, halted?: false, content: nil

  @type assigns :: map
  @type params :: map
  @type content :: String.t()

  @type t :: %__MODULE__{
          assigns: assigns(),
          params: params(),
          halted?: boolean(),
          content: content()
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
end
