defmodule Stopsel do
  @moduledoc """
  A stopsel is similar to a "plug".
  It accepts a message (`Stopsel.Message`), modifies it or
  prevents it from passing it further down the router.

  Similar to "plug"s a stopsel can be either a function or a
  module that implements the `Stopsel` behaviour.

  ## Module Stopsel
  A module stopsel must implement the callbacks `init/1` and `call/2`

  ### `init/1`
  Accepts a configuration and passes it as second parameter to `call/2`.
  Use this callback to prepare the configuration and if necessary evaluate
  its correctness.

  Currently the configuration is evaluated at runtime. This is subject to
  change in future versions.

  ### `call/2`
  Accepts a message and the evaluated configuration from `init/1`.

  Use this callback to edit the parameters and assigns of the message
  or halt the message if necessary. Must return a `Stopsel.Message`

  ## function stopsel
  A function stopsel will receive a message and a configuration, without
  preprocessing the configuration. Currently a function stopsel must be
  declared as atom that corresponds to an imported function.
  This is subject to change in future versions.

  Use this function to edit the  parameters and assigns or halt the message if necessary.
  Must return a `Stopsel.Message`
  """

  alias Stopsel.Message

  @type options :: any()
  @type config :: any()

  @callback init(options) :: config
  @callback call(Message.t(), config) :: Message.t()
end
