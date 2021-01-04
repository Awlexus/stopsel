defmodule Stopsel.Message do
  @moduledoc """
  A message contains information about a text message.

  A message has the original content, against which was matched against,
  assigns and parameters.

  Assigns can be arbitrarily added to the message,
  parameters on the other are assigned from the `Stopsel.Invoker` and
  contain the parameters that were declared in the matching route.
  """
  defstruct assigns: %{}, params: %{}, halted?: false, content: nil

  @type assigns :: map
  @type params :: map
  @type content :: String.t()

  @type halted_message :: %__MODULE__{halted?: true}

  @type t :: %__MODULE__{
          assigns: assigns(),
          params: params(),
          halted?: boolean(),
          content: content()
        }

  @doc """
  Adds an assign to the message or overwrites it.
  """
  @spec assign(t(), atom(), term()) :: t()
  def assign(%__MODULE__{assigns: assigns} = message, key, value) do
    %{message | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Adds many assigns or overwrites them.
  """
  @spec assign(t(), map() | Keyword.t()) :: t()
  def assign(%__MODULE__{assigns: assigns} = message, new_assigns) do
    %{message | assigns: Map.merge(assigns, Map.new(new_assigns))}
  end

  @doc """
  Halts a message and prevents it from advancing further down the pipeline.
  """
  @spec halt(t()) :: halted_message()
  def halt(%__MODULE__{} = message) do
    %{message | halted?: true}
  end

  @doc """
  Adds an parameter to the message or overwrites it.
  """
  @spec put_param(t(), atom(), term()) :: t()
  def put_param(%__MODULE__{params: params} = message, key, value) do
    %{message | params: Map.put(params, key, value)}
  end

  @doc """
  Adds many parametewrs or overwrites them.
  """
  @spec put_params(t(), map() | Keyword.t()) :: t()
  def put_params(%__MODULE__{params: old_params} = message, new_params) do
    %{message | params: Map.merge(old_params, Map.new(new_params))}
  end
end
