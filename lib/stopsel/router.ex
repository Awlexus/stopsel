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

          scope "calculator|:a", Calculator do
            stopsel :parse_number, :a
            stopsel :parse_number, :b

            command :add, "+|:b"
            command :subtract, "-|:b"
            command :multiply, "*|:b"
            command :divide, "/|:b"
          end
        end
      end

  """

  @doc false
  use GenServer

  alias Stopsel.Builder.Command

  @type path :: [String.t()]
  @type stopsel :: module() | function()
  @type opts :: any()
  @type params :: map()
  @type assigns :: map()
  @type router :: module()

  @type match :: {[{stopsel(), opts}], function(), assigns(), params()}
  @type match_error :: :no_match | {:multiple_matches, [match()]}
  @doc false
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc false
  def init(_), do: {:ok, nil}

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
  @spec unload_router(router()) :: boolean()
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
  @spec unload_route(router(), path()) :: boolean()
  def unload_route(router, path), do: GenServer.call(__MODULE__, {:unload_route, router, path})

  @doc """
  Tries to find a matching route in the given router.

      iex> Stopsel.Router.load_router(MyApp.Router)
      true
      iex> Stopsel.Router.match_route(MyApp.Router, ~w"hello")
      {:ok, %Stopsel.Builder.Command{path: ~w"hello", function: :hello, module: MyApp}}
      iex> Stopsel.Router.match_route(MyApp.Router, ~w"hellooo")
      {:error, :no_match}

  """
  @spec match_route(router(), path()) :: {:ok, match()} | {:error, match_error()}
  def match_route(router, path) do
    if router_exists?(router) do
      case :router.route(router, compile_path(path)) do
        [{:route, %Command{} = command, params}] ->
          {:ok, %{command | params: Map.new(params)}}

        [] ->
          {:error, :no_match}

        matches ->
          matches = Enum.map(matches, &elem(&1, 2))

          {:error, {:multiple_matches, matches}}
      end
    else
      {:error, :no_match}
    end
  end

  @doc """
  Returns a list of all the currently active routes of the router.
  """
  @spec routes(router()) :: [[String.t()]]
  def routes(router) do
    if router_exists?(router) do
      router
      |> :router.paths()
      |> Enum.map(fn path ->
        Enum.map(path, fn
          {:+, name} -> ":#{name}"
          name -> name
        end)
      end)
    else
      []
    end
  end

  def handle_call({:load_router, module}, _, state) do
    if router_exists?(module) do
      :router.delete(module)
    end

    :router.new(module)
    Enum.each(module.__commands__(), &add_route(module, &1))

    {:reply, true, state}
  end

  def handle_call({:unload_router, module}, _, state) do
    {:reply, router_exists?(module) && :router.delete(module), state}
  end

  def handle_call({:load_route, module, path}, _, state) do
    unless router_exists?(module) do
      :router.new(module)
    end

    result =
      case find_route(module, path) do
        nil ->
          false

        route ->
          add_route(module, route)
          true
      end

    {:reply, result, state}
  end

  def handle_call({:unload_route, module, path}, _, state) do
    result =
      with true <- router_exists?(module),
           route when not is_nil(route) <- find_route(module, path) do
        remove_route(module, route)
        true
      else
        _ -> false
      end

    {:reply, result, state}
  end

  defp find_route(module, path) do
    Enum.find(module.__commands__(), &(&1.path == path))
  end

  defp add_route(module, %Command{} = command) do
    :router.add(module, compile_path(command.path), command)
  end

  defp remove_route(module, %Command{} = command) do
    :router.remove_path(module, compile_path(command.path), command)
  end

  defp compile_path(path) do
    Enum.map(path, fn
      ":" <> param -> {:+, String.to_atom(param)}
      segment -> segment
    end)
  end

  defp router_exists?(module) do
    try do
      :router.info(module)
      true
    catch
      :not_found -> false
    end
  end
end
