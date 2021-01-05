defmodule MyApp.Router do
  import Stopsel.Builder

  import MyApp.NumberUtils,
    only: [parse_number: 2],
    warn: false

  router MyApp do
    command :hello

    scope "calculator|:a", Calculator do
      stopsel :parse_number, :a
      stopsel :parse_number, :b

      command :add, "+|:b"
      command :subtract, "-|:b"
      command :multiply, "*|:b"
      command :divide, "/|:b"
    end
  end
end
