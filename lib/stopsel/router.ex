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
  def init(_) do
    table = :ets.new(__MODULE__, [:named_table, :protected, {:read_concurrency, true}])
    {:ok, table}
  end

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
    with [{_, node}] <- :ets.lookup(__MODULE__, router),
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
    with [{_, node}] <- :ets.lookup(__MODULE__, router) do
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

  @doc """
  Returns a list of all loaded commands for this router
  """
  @spec loaded_commands(router()) :: [Command.t()]
  def loaded_commands(router) do
    with [{_, node}] <- :ets.lookup(__MODULE__, router) do
      Node.values(node)
    end
  end

  def find_route(module, path) do
    Enum.find(module.__commands__(), &(&1.path == path))
  end

  ### GenServer handles

  def handle_call({:load_router, module}, _, table) do
    node =
      Enum.reduce(
        module.__commands__(),
        Node.new(),
        &Node.insert(&2, compile_path(&1.path), &1)
      )

    :ets.insert(table, {module, node})

    {:reply, true, table}
  end

  def handle_call({:unload_router, module}, _, table) do
    with [{_, node}] <- :ets.lookup(table, module) do
      node
      |> Node.values()
      |> Enum.each(&Command.free_docs/1)
    end

    :ets.delete(table, module)
    {:reply, true, table}
  end

  def handle_call({:load_route, module, path}, _, table) do
    result =
      case find_route(module, path) do
        nil ->
          false

        route ->
          update_node(module, &Node.insert(&1, compile_path(path), route))
          true
      end

    {:reply, result, table}
  end

  def handle_call({:unload_route, module, path}, _, table) do
    result =
      if command = find_route(module, path) do
        Command.free_docs(command)
        update_node(module, &Node.delete(&1, path))
        true
      else
        false
      end

    {:reply, result, table}
  end

  def handle_call({:nodes, module}, _, table) do
    result =
      case :ets.lookup(table, module) do
        [{_, node}] -> node
        _ -> nil
      end

    {:reply, result, table}
  end

  defp compile_path(path) do
    Enum.map(path, fn
      ":" <> param -> String.to_atom(param)
      segment -> segment
    end)
  end

  defp update_node(module, fun) do
    node =
      case :ets.lookup(__MODULE__, module) do
        [{_, node}] -> node
        _ -> Node.new()
      end

    :ets.insert(__MODULE__, {module, fun.(node)})
  end
end
