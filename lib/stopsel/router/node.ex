defmodule Stopsel.Router.Node do
  import Record
  import Kernel, except: [node: 0, node: 1]

  @type value :: any()
  @type nodes :: map()
  @type t :: {:node, value, nodes}

  defrecord :node, value: nil, nodes: %{}

  def new(value \\ nil), do: node(value: value)

  def insert(node, _, nil), do: node
  def insert(node, [], value), do: node(node, value: value)

  def insert(node, [h | t], value) do
    nodes = node(node, :nodes)

    new_node =
      nodes
      |> Map.get(h, new())
      |> insert(t, value)

    node(node, nodes: Map.put(nodes, h, new_node))
  end

  def delete(node, []) do
    node(node, value: nil)
  end

  def delete(node, [h | t]) do
    nodes = node(node, :nodes)

    case nodes do
      %{^h => next_node} ->
        new_node = delete(next_node, t)

        new_nodes =
          if empty?(new_node) do
            Map.delete(nodes, h)
          else
            Map.put(nodes, h, new_node)
          end

        node(node, nodes: new_nodes)

      _ ->
        node
    end
  end

  def delete_all(node, [h]) do
    nodes = node(node, :nodes)
    new_nodes = Map.delete(nodes, h)
    node(node, nodes: new_nodes)
  end

  def delete_all(node, [h | t]) do
    nodes = node(node, :nodes)

    case nodes do
      %{^h => next_node} ->
        new_node = delete_all(next_node, t)

        new_nodes =
          if empty?(new_node) do
            Map.delete(nodes, h)
          else
            Map.put(nodes, h, new_node)
          end

        node(node, nodes: new_nodes)

      _ ->
        node
    end
  end

  def search_next(node, segment) do
    case node(node, :nodes) do
      %{^segment => node} -> node
      _ -> nil
    end
  end

  def search(nil, _), do: nil

  def search(node, path) do
    Enum.reduce_while(path, node, fn segment, node ->
      case search_next(node, segment) do
        nil -> {:halt, nil}
        node -> {:cont, node}
      end
    end)
  end

  def empty?(node(value: nil, nodes: nodes)) when nodes == %{}, do: true
  def empty?(_), do: false

  def active_paths(node, path \\ []) do
    paths =
      Enum.flat_map(node(node, :nodes), fn {key, node} ->
        active_paths(node, [key | path])
      end)

    if node(node, :value) do
      [:lists.reverse(path) | paths]
    else
      paths
    end
  end

  def values(nil), do: []

  def values(node) do
    node(value: value, nodes: nodes) = node
    values = Enum.flat_map(nodes, &values(elem(&1, 1)))

    if value do
      [value | values]
    else
      values
    end
  end
end
