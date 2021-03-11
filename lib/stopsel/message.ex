defmodule Stopsel.Message do
  @moduledoc """
  Represents a text message.

  A message has the original content, against which was matched against,
  assigns and parameters.

  Assigns can be arbitrarily added to the message,
  parameters on the other are assigned from the `Stopsel.Invoker` and
  contain the parameters that were declared in the matching route.
  """
  defstruct assigns: %{}, params: %{}, halted?: false, content: nil, rest: nil

  @type assigns :: map
  @type params :: map
  @type content :: String.t()
  @type rest :: String.t() | nil

  @type halted_message :: %__MODULE__{
          assigns: assigns(),
          params: params(),
          content: content(),
          halted?: true,
          rest: rest()
        }

  @type t :: %__MODULE__{
          assigns: assigns(),
          params: params(),
          halted?: boolean(),
          content: content(),
          rest: rest()
        }

  @doc """
  Adds an assign to the message or overwrites it.

      iex> Stopsel.Message.assign(%Stopsel.Message{}, :key, :value)
      %Stopsel.Message{assigns: %{key: :value}}

      iex> assigns = %{key: :old_value}
      iex> Stopsel.Message.assign(%Stopsel.Message{assigns: assigns}, :key, :new_value)
      %Stopsel.Message{assigns: %{key: :new_value}}

  """
  @spec assign(t(), atom(), term()) :: t()
  def assign(%__MODULE__{assigns: assigns} = message, key, value) do
    %{message | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Adds many assigns or overwrites them.

      iex> Stopsel.Message.assign(%Stopsel.Message{}, key: :value)
      %Stopsel.Message{assigns: %{key: :value}}

      iex> assigns = %{key: :old_value}
      iex> Stopsel.Message.assign(%Stopsel.Message{assigns: assigns}, key: :new_value)
      %Stopsel.Message{assigns: %{key: :new_value}}

  """
  @spec assign(t(), map() | Keyword.t()) :: t()
  def assign(%__MODULE__{assigns: assigns} = message, new_assigns) do
    %{message | assigns: Map.merge(assigns, Map.new(new_assigns))}
  end

  @doc """
  Prevents a message from advancing further down the pipeline.

      iex> Stopsel.Message.halt(%Stopsel.Message{})
      %Stopsel.Message{halted?: true}

  """
  @spec halt(t()) :: halted_message()
  def halt(%__MODULE__{} = message) do
    %{message | halted?: true}
  end

  @doc """
  Adds an parameter to the message or overwrites it.

      iex> Stopsel.Message.put_param(%Stopsel.Message{}, :key, :value)
      %Stopsel.Message{params: %{key: :value}}

      iex> params = %{key: :old_value}
      iex> Stopsel.Message.put_param(%Stopsel.Message{params: params}, :key, :new_value)
      %Stopsel.Message{params: %{key: :new_value}}

  """
  @spec put_param(t(), atom(), term()) :: t()
  def put_param(%__MODULE__{params: params} = message, key, value) do
    %{message | params: Map.put(params, key, value)}
  end

  @doc """
  Adds many parameters or overwrites them.

      iex> Stopsel.Message.put_params(%Stopsel.Message{}, key: :value)
      %Stopsel.Message{params: %{key: :value}}

      iex> params = %{key: :old_value}
      iex> Stopsel.Message.put_params(%Stopsel.Message{params: params}, key: :new_value)
      %Stopsel.Message{params: %{key: :new_value}}

  """
  @spec put_params(t(), map() | Keyword.t()) :: t()
  def put_params(%__MODULE__{params: old_params} = message, new_params) do
    %{message | params: Map.merge(old_params, Map.new(new_params))}
  end
end
