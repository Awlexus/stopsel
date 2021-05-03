defmodule Stopsel.Command do
  @moduledoc """
  Represents a command.
  """

  defstruct path: nil,
            stopsel: [],
            module: nil,
            function: nil,
            assigns: %{},
            params: %{},
            rest: []

  @type path :: [String.t()]
  @type command_function :: atom()
  @type stopsel_opts :: any()
  @type stopsel :: {module() | {module(), command_function()}, stopsel_opts()}
  @type assigns :: map()
  @type params :: map()
  @type rest :: [String.t()]

  @type t :: %__MODULE__{
          path: path(),
          stopsel: [stopsel()],
          module: module(),
          function: command_function(),
          assigns: assigns(),
          params: assigns(),
          rest: rest()
        }

  @doc """
  Remove module documentation from cache
  """
  @spec free_docs(t()) :: :ok
  def free_docs(%__MODULE__{module: module, function: function}) do
    :persistent_term.erase({__MODULE__, module, function, :short})
    :persistent_term.erase({__MODULE__, module, function, :long})
    :ok
  end

  @doc """
  Fetch the short documentation of the command.

  The short documentation consists only of the first paragraph
  of the documentation and is fetched on demand.
  """
  @spec short_help(t()) :: String.t() | nil
  def short_help(%__MODULE__{module: module, function: function} = command) do
    try do
      :persistent_term.get({__MODULE__, module, function, :short})
    rescue
      ArgumentError ->
        with {short, _} <- generate_docs(command) do
          short
        end
    end
  end

  @doc """
  Fetch the documentation of the command.

  The documentation is fetched on demand.
  """
  @spec help(t()) :: String.t() | nil
  def help(%__MODULE__{module: module, function: function} = command) do
    try do
      :persistent_term.get({__MODULE__, module, function, :long})
    rescue
      ArgumentError ->
        with {short, _} <- generate_docs(command) do
          short
        end
    end
  end

  defp generate_docs(%__MODULE__{module: module, function: function}) do
    case fetch_docs(module, function) do
      nil ->
        :persistent_term.put({__MODULE__, module, function, :short}, nil)
        :persistent_term.put({__MODULE__, module, function, :long}, nil)
        nil

      doc ->
        [short | _] = String.split(doc, ~r/\n\s*\n/, parts: 2)
        :persistent_term.put({__MODULE__, module, function, :short}, String.trim(short))
        :persistent_term.put({__MODULE__, module, function, :long}, doc)
        {short, doc}
    end
  end

  defp fetch_docs(module, function) do
    {_, _, _, _, _, _, functions} = Code.fetch_docs(module)

    matcher = fn
      {{:function, ^function, 2}, _, _, %{"en" => docs}, _} -> docs
      _ -> nil
    end

    Enum.find_value(functions, matcher)
  end
end
