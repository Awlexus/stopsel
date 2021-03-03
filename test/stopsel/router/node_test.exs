defmodule Stopsel.Router.NodeTest do
  use ExUnit.Case, async: true
  alias Stopsel.Router.Node
  import Kernel, except: [node: 0, node: 1]

  import Node, only: [node: 0, node: 1, node: 2]

  describe "new/0" do
    test "creates new node" do
      assert node() == Node.new()
    end
  end

  describe "insert/3" do
    test "inserts node" do
      node =
        Node.new()
        |> Node.insert(~w"hello", :world)

      assert node(nodes: %{"hello" => Node.new(:world)}) == node
    end

    test "can be nested" do
      node =
        Node.new()
        |> Node.insert(~w"hello world", :hello_back)

      result = node(nodes: %{"hello" => node(nodes: %{"world" => Node.new(:hello_back)})})

      assert result == node
    end

    test "can be siblings nested" do
      node =
        Node.new()
        |> Node.insert(~w"hello world", :value)
        |> Node.insert(~w"hello back", :value)

      result =
        node(
          nodes: %{
            "hello" =>
              node(
                nodes: %{
                  "world" => Node.new(:value),
                  "back" => Node.new(:value)
                }
              )
          }
        )

      assert result == node
    end
  end

  describe "delete/2" do
    test "can delete a node" do
      node =
        Node.new()
        |> Node.insert(~w"hello", :value)
        |> Node.delete(~w"hello")

      assert node == Node.new()
    end

    test "deletes node inbetween if they are empty" do
      node =
        Node.new()
        |> Node.insert(~w"hello world", :value)
        |> Node.delete(~w"hello world")

      assert node == Node.new()
    end

    test "doesn't delete nodes inbetween if there's a sibling node" do
      node =
        Node.new()
        |> Node.insert(~w"hello world", :value)
        |> Node.insert(~w"hello back", :value)
        |> Node.delete(~w"hello world")

      assert Node.new() |> Node.insert(~w"hello back", :value) == node
    end

    test "doesn't delete nodes after the given path" do
      node =
        Node.new()
        |> Node.insert(~w"hello", :value)
        |> Node.insert(~w"hello world", :value)
        |> Node.delete(~w"hello")

      expected = Node.insert(Node.new(), ~w"hello world", :value)

      assert node == expected
    end
  end

  describe "delete_all/2" do
    test "deletes all nodes after the mentioned path" do
      node =
        Node.new()
        |> Node.insert(~w"hello", :value)
        |> Node.insert(~w"hello world", :value)
        |> Node.delete_all(~w"hello")

      assert node == Node.new()
    end

    test "deletes upper nodes, if they have no value" do
      node =
        Node.new()
        |> Node.insert(~w"hello world", :value)
        |> Node.delete_all(~w"hello world")

      assert node == Node.new()
    end

    test "Deletes upper nodes until a value is found" do
      node =
        Node.new()
        |> Node.insert(~w"hello", :value)
        |> Node.insert(~w"hello world world", :value)
        |> Node.delete_all(~w"hello world world")

      expected =
        Node.new()
        |> Node.insert(~w"hello", :value)

      assert node == expected
    end
  end

  describe "search_next/2" do
    test "finds then next node under the given segment" do
      node =
        Node.new()
        |> Node.insert(~w"hello", :value)

      assert Node.search_next(node, "hello") == Node.new(:value)
    end

    test "returns null if the next node was not found" do
      assert Node.search_next(Node.new(), "hello") == nil
    end
  end

  describe "search/2" do
    test "finds next node" do
      node =
        Node.new()
        |> Node.insert(~w"hello", :value)
        |> Node.search(~w"hello")

      assert node == Node.new(:value)
    end

    test "finds nested node" do
      node =
        Node.new()
        |> Node.insert(~w"hello world", :value)
        |> Node.search(~w"hello world")

      assert node == Node.new(:value)
    end

    test "returns nil if path was not found" do
      node =
        Node.new()
        |> Node.search(~w"test")

      assert node == nil
    end
  end
end
