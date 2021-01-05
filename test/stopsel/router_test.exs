defmodule Stopsel.RouterTest do
  use ExUnit.Case

  doctest Stopsel.Router

  test "does not load routes twice" do
    Stopsel.Router.load_route(MyApp.Router, ~w"hello")
    Stopsel.Router.load_route(MyApp.Router, ~w"hello")
    {:ok, _} = Stopsel.Router.match_route(MyApp.Router, ~w"hello")
  end

  test "returns error when multiple matches where found" do
    Stopsel.Router.unload_router(MyApp.Router)

    :router.new(MyApp.Router)
    :router.add(MyApp.Router, ~w"hello", {:a, :b, :c})
    :router.add(MyApp.Router, ~w"hello", {:a, :b, :d})

    {:error, {:multiple_matches, _}} = Stopsel.Router.match_route(MyApp.Router, ~w"hello")
  end
end
