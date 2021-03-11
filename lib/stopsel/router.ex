defmodule Stopsel.Router do
  @moduledoc """
  This module is responsible for managing the active routes of a router.

  A router must first be loaded, before it can be used.

  Examples below will use the the following router

      defmodule MyApp.Router do
        import Stopsel.Builder

        import MyApp.NumberUtils,
          only: [parse_number: 2],
          warn: false

        router MyApp do
          command :hello

          scope "calculator :a", Calculator do
            stopsel :parse_number, :a
            stopsel :parse_number, :b

            command :add, path: "+ :b"
            command :subtract, path: "- :b"
            command :multiply, path: "* :b"
            command :divide, path: "/ :b"
          end
        end
      end

  """

  @doc false
  use GenServer

  alias Stopsel.Command
  alias Stopsel.Router.Node
  require Node
  import Kernel, except: [node: 0, node: 1]

  @type path :: [String.t()]
  @type router :: module()

  @type match_error :: :no_match
  @doc false
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc false
  def init(_), do: {:ok, Node.new()}

  @doc """
  Loads all commands from the given module into the router.

  Reloads all routes of the router, if they have been unloaded.

      iex> Stopsel.Router.load_router(MyApp.Router)
      true
      iex> Stopsel.Router.routes(MyApp.Router) |> Enum.sort()
      [
        ["calculator", ":a", "*", ":b"],
        ["calculator", ":a", "+", ":b"],
        ["calculator", ":a", "-", ":b"],
        ["calculator", ":a", "/", ":b"],
        ["hello"]
      ]

  """
  @spec load_router(router()) :: true
  def load_router(router), do: GenServer.call(__MODULE__, {:load_router, router})

  @doc """
  Removes the given module from the router.

      iex> Stopsel.Router.load_router(MyApp.Router) != []
      true
      iex> Stopsel.Router.unload_router(MyApp.Router)
      true
      iex> Stopsel.Router.routes(MyApp.Router) == []
      true

  """
  @spec unload_router(router()) :: true
  def unload_router(router), do: GenServer.call(__MODULE__, {:unload_router, router})

  @doc """
  Loads one route that was previously removed back into the router.

      iex> Stopsel.Router.unload_router(MyApp.Router)
      iex> Stopsel.Router.load_route(MyApp.Router, ~w"hello")
      true
      iex> Stopsel.Router.routes(MyApp.Router)
      [["hello"]]

  """
  @spec load_route(router(), path()) :: boolean()
  def load_route(router, path), do: GenServer.call(__MODULE__, {:load_route, router, path})

  @doc """
  Unloads one route from the router.

      iex> Stopsel.Router.load_router(MyApp.Router)
      true
      iex> Stopsel.Router.unload_route(MyApp.Router, ~w"hello")
      true
      iex> ~w"hello" in Stopsel.Router.routes(MyApp.Router)
      false

  """
  @spec unload_route(router(), path()) :: true
  def unload_route(router, path), do: GenServer.call(__MODULE__, {:unload_route, router, path})

  @doc """
  Tries to find a matching route in the given router.

      iex> Stopsel.Router.load_router(MyApp.Router)
      true
      iex> Stopsel.Router.match_route(MyApp.Router, ~w"hello")
      {:ok, %Stopsel.Command{path: ~w"hello", function: :hello, module: MyApp}}
      iex> Stopsel.Router.match_route(MyApp.Router, ~w"hellooo")
      {:error, :no_match}

  """
  @spec match_route(router(), path()) ::
          {:ok, Command.t()} | {:error, match_error()}
  def match_route(router, path) do
    with node when node != nil <- node(router),
         %Command{} = command <- do_match(node, path, %{}) do
      {:ok, command}
    else
      _ -> {:error, :no_match}
    end
  end

  defp do_match(node, [], params) do
    if command = Node.node(node, :value), do: %{command | params: params}
  end

  defp do_match(node, [h | t], params) do
    nodes = Node.node(node, :nodes)

    cond do
      next = Map.get(nodes, h) ->
        do_match(next, t, params)

      Enum.any?(nodes, &is_atom(elem(&1, 0))) ->
        nodes
        |> Enum.filter(&is_atom(elem(&1, 0)))
        |> Enum.find_value(fn {param, node} ->
          do_match(node, t, Map.put(params, param, h))
        end)

      nodes == %{} ->
        case Node.node(node, :value) do
          %Command{} = command ->
            %{command | params: params, rest: [h | t]}

          _ ->
            nil
        end

      true ->
        nil
    end
  end

  @doc """
  Returns a list of all the currently active routes of the router.
  """
  @spec routes(router()) :: [[String.t()]]
  def routes(router) do
    case node(router) do
      nil ->
        []

      node ->
        node
        |> Node.active_paths()
        |> Enum.map(fn path ->
          Enum.map(path, fn
            segment when is_atom(segment) -> ":" <> to_string(segment)
            segment -> segment
          end)
        end)
    end
  end

  def handle_call({:load_router, module}, _, node) do
    node = Node.delete_all(node, [module])

    node =
      Enum.reduce(
        module.__commands__(),
        node,
        &Node.insert(&2, [module | compile_path(&1.path)], &1)
      )

    {:reply, true, node}
  end

  def handle_call({:unload_router, module}, _, node) do
    {:reply, true, Node.delete_all(node, [module])}
  end

  def handle_call({:load_route, module, path}, _, node) do
    {result, node} =
      case find_route(module, path) do
        nil -> {false, node}
        route -> {true, Node.insert(node, [module | compile_path(path)], route)}
      end

    {:reply, result, node}
  end

  def handle_call({:unload_route, module, path}, _, node) do
    {result, node} =
      if find_route(module, path) do
        {true, Node.delete(node, [module | path])}
      else
        {false, node}
      end

    {:reply, result, node}
  end

  def handle_call({:nodes, router_name}, _, router) do
    {:reply, Node.search_next(router, router_name), router}
  end

  def find_route(module, path) do
    Enum.find(module.__commands__(), &(&1.path == path))
  end

  defp node(router), do: GenServer.call(__MODULE__, {:nodes, router})

  defp compile_path(path) do
    Enum.map(path, fn
      ":" <> param -> String.to_atom(param)
      segment -> segment
    end)
  end
end
