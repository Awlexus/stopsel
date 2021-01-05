defmodule Stopsel.Command do
  @moduledoc """
  Represents a command.
  """

  defstruct path: nil,
            stopsel: [],
            module: nil,
            function: nil,
            assigns: %{},
            params: %{}

  @type path :: [String.t()]
  @type command_function :: atom()
  @type stopsel_opts :: any()
  @type stopsel :: {module() | {module(), command_function()}, stopsel_opts()}
  @type assigns :: map()
  @type params :: map()

  @type t :: %__MODULE__{
          path: path(),
          stopsel: [stopsel()],
          module: module(),
          function: command_function(),
          assigns: assigns(),
          params: assigns()
        }
end
