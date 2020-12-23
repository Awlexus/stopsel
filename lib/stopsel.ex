defmodule Stopsel do
  alias Stopsel.Message

  @type options :: any()
  @type config :: any()

  @callback init(options) :: config
  @callback call(Message.t(), config) :: Message.t()
end
