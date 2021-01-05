defmodule Stopsel.BuilderTest do
  use ExUnit.Case

  describe "router/2" do
    test "allows only one router per module" do
      assert_raise(Stopsel.RouterAlreadyDefinedError, fn ->
        defmodule Invalid do
          import Stopsel.Builder

          router do
          end

          router do
          end
        end
      end)
    end

    test "defines __commands__" do
      defmodule Test do
        import Stopsel.Builder

        router do
        end
      end

      assert Test.__commands__() == []
    end

    test "adds initial alias" do
      defmodule Test do
        import Stopsel.Builder

        router MyApp do
          command(:hello)
        end
      end

      function = &MyApp.hello/2
      [{["hello"], [], ^function, []}] = Test.__commands__()
    end
  end

  describe "scope/3" do
    test "cannot be called outside of router" do
      assert_raise Stopsel.OutsideOfRouterError, fn ->
        defmodule Invalid do
          import Stopsel.Builder

          scope do
          end
        end
      end
    end

    test "adds alias" do
      defmodule Test do
        import Stopsel.Builder

        router do
          scope nil, MyApp do
            command(:hello)
          end
        end
      end

      function = &MyApp.hello/2
      [{["hello"], [], ^function, []}] = Test.__commands__()
    end

    test "adds to path" do
      defmodule Test do
        import Stopsel.Builder

        router MyApp do
          scope "scope" do
            command(:hello)
          end
        end
      end

      [{~w"scope hello", [], _, []}] = Test.__commands__()
    end

    test "scopes stopsel" do
      defmodule Test do
        import Stopsel.Builder
        import MyApp.NumberUtils, warn: false

        router MyApp do
          scope do
            stopsel(:parse_number, :a)
          end

          command(:hello)
        end
      end

      [{~w"hello", [], _, []}] = Test.__commands__()
    end
  end

  describe "command/3" do
    test "cannot be called outside of router" do
      assert_raise Stopsel.OutsideOfRouterError, fn ->
        defmodule Invalid do
          import Stopsel.Builder

          command(:hello)
        end
      end
    end

    test "ensures aliased function exists" do
      assert_raise UndefinedFunctionError, fn ->
        defmodule Invalid do
          import Stopsel.Builder

          router MyApp do
            command(:helloooo)
          end
        end
      end
    end

    test "uses path when given" do
      defmodule Test do
        import Stopsel.Builder

        router MyApp do
          command(:hello, "hihi")
        end
      end

      [{~w"hihi", [], _, []}] = Test.__commands__()
    end

    test "adds name as path if none was given" do
      defmodule Test do
        import Stopsel.Builder

        router MyApp do
          command(:hello)
        end
      end

      [{~w"hello", [], _, []}] = Test.__commands__()
    end
  end

  describe "stopsel/2" do
    test "cannot be called outside of router" do
      assert_raise Stopsel.OutsideOfRouterError, fn ->
        defmodule Invalid do
          import Stopsel.Builder
          import MyApp.NumberUtils, warn: false

          stopsel(:parse_number, :a)
        end
      end
    end

    test "adds stopsel to pipeline" do
      defmodule Test do
        import Stopsel.Builder

        router MyApp do
          stopsel(MyApp.PseudoStopsel)
          command(:hello)
        end
      end

      [{_, [{MyApp.PseudoStopsel, _}], _, _}] = Test.__commands__()
    end

    test "supports module stopsel" do
      defmodule Test do
        import Stopsel.Builder

        router MyApp do
          stopsel(MyApp.PseudoStopsel)
          command(:hello)
        end
      end
    end

    test "supports supports imported functions" do
      defmodule Test do
        import Stopsel.Builder
        import MyApp.NumberUtils

        router MyApp do
          stopsel(:parse_number)
          command(:hello)
        end
      end
    end
  end
end
