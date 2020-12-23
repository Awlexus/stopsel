defmodule Stopsel.ExampleRouter do
  import Stopsel.Builder

  import Stopsel.Commands.Calculator, only: [parse_number: 2], warn: false

  router Stopsel.Commands do
    scope "do" do
      scope "calculate|:a|:b", Calculator do
        stopsel(:parse_number, :a)
        stopsel(:parse_number, :b)

        command(:add)
        command(:subtract)
        command(:multiply)
        command(:divide)
      end

      command(:shout, "shout|:rest")
      command(:whisper, "whisper|:rest")
    end
  end
end
