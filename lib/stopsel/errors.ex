defmodule Stopsel.OutsideOfRouterError do
  @moduledoc "Raised when a builder function was called outside of a router definition."

  defexception [:message]

  def exception({macro, arity}) do
    msg = "#{macro}/#{arity} was called from outside a router definition"

    %__MODULE__{message: msg}
  end
end

defmodule Stopsel.RouterAlreadyDefinedError do
  @moduledoc "Raised when a router has already been defined in the current module."

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Stopsel.InvalidStopsel do
  @moduledoc "Raised when the a stopsel does not evaluate into a valid plug."

  defexception [:message]

  def exception(stopsel) do
    message = "#{stopsel} does not evaluate to a valid module stopsel or function"
    %__MODULE__{message: message}
  end
end

defmodule Stopsel.InvalidMessage do
  @moduledoc "Raised when a `Stopsel.Message` was expected."

  defexception [:message]

  def exception(other) do
    message = "A %Stopsel.Message{} was expected, got #{inspect other}"

    %__MODULE__{message: message}
  end
end
