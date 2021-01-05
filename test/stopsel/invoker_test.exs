defmodule Stopsel.InvokerTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  doctest Stopsel.Invoker

  test "Applies stopsel" do
    Stopsel.Router.load_router(MyApp.Router)

    io =
      capture_io(fn ->
        assert {:ok, :ok} == Stopsel.Invoker.invoke("calculator 1 + 2", MyApp.Router)
      end)

    assert io == "1 + 2 = 3\n"
  end
end
