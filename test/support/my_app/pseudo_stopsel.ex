defmodule MyApp.PseudoStopsel do
  @behaviour Stopsel

  def init(opts), do: opts
  def call(message, _), do: message
end
