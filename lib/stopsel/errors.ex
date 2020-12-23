defmodule Stopsel.OutsideOfRouterError do
  defexception [:message]

  def exception({macro, arity}) do
    msg = "#{macro}/#{arity} was called from outside a router definition"

    %__MODULE__{message: msg}
  end
end

defmodule Stopsel.RouterAlreadyDefinedError do
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Stopsel.InvalidStopsel do
  defexception [:message]

  def exception(stopsel) do
    message = "#{stopsel} does not evaluate to a valid module stopsel or function"
    %__MODULE__{message: message}
  end
end
