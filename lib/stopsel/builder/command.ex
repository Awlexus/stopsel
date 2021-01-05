defmodule Stopsel.Builder.Command do
  defstruct [
    path: nil,
    stopsel: [],
    module: nil,
    function: nil,
    assigns: %{},
    params: %{}
  ]

end
