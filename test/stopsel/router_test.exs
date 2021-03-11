defmodule Stopsel.RouterTest do
  use ExUnit.Case

  doctest Stopsel.Router

  test "does not load routes twice" do
    Stopsel.Router.load_route(MyApp.Router, ~w"hello")
    Stopsel.Router.load_route(MyApp.Router, ~w"hello")
    {:ok, _} = Stopsel.Router.match_route(MyApp.Router, ~w"hello")
  end
end
