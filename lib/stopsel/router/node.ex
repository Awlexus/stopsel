defmodule Stopsel.Router.Node do
  import Record
  import Kernel, except: [node: 0, node: 1]

  @type value :: any()
  @type nodes :: map()
  @type t :: {:node, value, nodes}

  defrecord :node, value: nil, nodes: %{}

  def new(value \\ nil), do: node(value: value)

  def insert(node, [], value), do: node(node, value: value)

  def insert(node, [h | t], value) do
    nodes = node(node, :nodes)

    new_node =
      nodes
      |> Map.get(h, new())
      |> insert(t, value)

    node(node, nodes: Map.put(nodes, h, new_node))
  end

  def delete(node, [h | t]) do
    case search_next(node, h) do
      nil ->
        node

      next_node ->
        nodes = node(node, :nodes)

        new_nodes =
          case do_delete(next_node, t) do
            nil -> Map.delete(nodes, h)
            new_node -> Map.put(nodes, h, new_node)
          end

        node(node, nodes: new_nodes)
    end
  end

  def search_next(node, segment) do
    case node(node, :nodes) do
      %{^segment => node} -> node
      _ -> nil
    end
  end

  def search(node, path) do
    Enum.reduce_while(path, node, fn segment, node ->
      case search_next(node, segment) do
        nil -> {:halt, nil}
        node -> {:cont, node}
      end
    end)
  end

  defp do_delete(node, []) do
    if Enum.empty?(node(node, :nodes)) do
      nil
    else
      node(node, value: nil)
    end
  end

  defp do_delete(node, [h | t]) do
    case node(node, :nodes) do
      %{^h => next_node} = nodes ->
        case do_delete(next_node, t) do
          nil ->
            case Map.delete(nodes, h) do
              empty when empty == %{} ->
                nil

              new_nodes ->
                node(node, nodes: new_nodes)
            end
        end

      _ ->
        node
    end
  end
end
