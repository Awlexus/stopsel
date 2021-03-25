defmodule Stopsel.BuilderTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Stopsel.Command

  describe "router/2" do
    test "allows only one router per module" do
      capture_io(:stderr, fn ->
        assert_raise(Stopsel.RouterAlreadyDefinedError, fn ->
          defmodule Invalid do
            import Stopsel.Builder

            router do
            end

            router do
            end
          end
        end)
      end)
    end

    test "defines __commands__" do
      capture_io(:stderr, fn ->
        defmodule Test do
          import Stopsel.Builder

          router do
          end
        end

        assert Test.__commands__() == []
      end)
    end

    test "adds initial alias" do
      capture_io(:stderr, fn ->
        defmodule Test do
          import Stopsel.Builder

          router MyApp do
            command(:hello)
          end
        end

        assert [%Command{path: ~w"hello", function: :hello, module: MyApp}] == Test.__commands__()
      end)
    end
  end

  describe "scope/3" do
    test "cannot be called outside of router" do
      capture_io(:stderr, fn ->
        assert_raise Stopsel.OutsideOfRouterError, fn ->
          defmodule Invalid do
            import Stopsel.Builder

            scope do
            end
          end
        end
      end)
    end

    test "adds alias" do
      capture_io(:stderr, fn ->
        defmodule Test do
          import Stopsel.Builder

          router do
            scope nil, MyApp do
              command(:hello)
            end
          end
        end

        assert [%Command{path: ~w"hello", function: :hello, module: MyApp}] == Test.__commands__()
      end)
    end

    test "adds to path" do
      capture_io(:stderr, fn ->
        defmodule Test do
          import Stopsel.Builder

          router MyApp do
            scope "scope" do
              command(:hello)
            end
          end
        end

        assert [%Command{path: ~w"scope hello", function: :hello, module: MyApp}] ==
                 Test.__commands__()
      end)
    end

    test "scopes stopsel" do
      capture_io(:stderr, fn ->
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

        assert [%Command{path: ~w"hello", function: :hello, module: MyApp}] ==
                 Test.__commands__()
      end)
    end
  end

  describe "command/3" do
    test "cannot be called outside of router" do
      capture_io(:stderr, fn ->
        assert_raise Stopsel.OutsideOfRouterError, fn ->
          defmodule Invalid do
            import Stopsel.Builder

            command(:hello)
          end
        end
      end)
    end

    test "warns when the function doesn't exist" do
      io =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          defmodule Invalid do
            import Stopsel.Builder

            router MyApp do
              command(:helloooo)
            end
          end
        end)

      assert io =~ "Elixir.MyApp.helloooo/2 does not exist"
    end

    test "uses path when given" do
      capture_io(:stderr, fn ->
        defmodule Test do
          import Stopsel.Builder

          router MyApp do
            command(:hello, path: "hihi")
          end
        end

        assert [%Command{path: ~w"hihi", function: :hello, module: MyApp}] == Test.__commands__()
      end)
    end

    test "adds name as path if none was given" do
      capture_io(:stderr, fn ->
        defmodule Test do
          import Stopsel.Builder

          router MyApp do
            command(:hello)
          end
        end

        assert [%Command{path: ~w"hello", function: :hello, module: MyApp}] == Test.__commands__()
      end)
    end
  end

  describe "stopsel/2" do
    test "cannot be called outside of router" do
      capture_io(:stderr, fn ->
        assert_raise Stopsel.OutsideOfRouterError, fn ->
          defmodule Invalid do
            import Stopsel.Builder
            import MyApp.NumberUtils, warn: false

            stopsel(:parse_number, :a)
          end
        end
      end)
    end

    test "adds stopsel to pipeline" do
      capture_io(:stderr, fn ->
        defmodule Test do
          import Stopsel.Builder

          router MyApp do
            stopsel(MyApp.PseudoStopsel)
            command(:hello)
          end
        end

        command = %Command{
          path: ~w"hello",
          function: :hello,
          module: MyApp,
          stopsel: [{MyApp.PseudoStopsel, []}]
        }

        assert [command] == Test.__commands__()
      end)
    end

    test "supports module stopsel" do
      capture_io(:stderr, fn ->
        defmodule Test do
          import Stopsel.Builder

          router MyApp do
            stopsel(MyApp.PseudoStopsel)
            command(:hello)
          end
        end
      end)
    end

    test "supports supports imported functions" do
      capture_io(:stderr, fn ->
        defmodule Test do
          import Stopsel.Builder
          import MyApp.NumberUtils

          router MyApp do
            stopsel(:parse_number)
            command(:hello)
          end
        end
      end)
    end
  end
end
