defmodule Stopsel.Router do
  @type path :: [String.t()]
  @type stopsel :: module() | function()
  @type opts :: any()
  @type params :: map()
  @type assigns :: map()

  @type match :: {[{stopsel(), opts}], function(), assigns(), params()}
  @type match_error :: :no_match | {:multiple_matches, [match()]}

  @doc """
  Load all commands from the given module into the router.
  Can also be used to reset the router for the given module.
  """
  @spec load_module(module()) :: :ok
  def load_module(module) do
    if router_exists?(module) do
      :router.delete(module)
    end

    :router.new(module)

    Enum.each(module.__commands__(), &add_route(module, &1))
  end

  @doc """
  Remove the given module from the router
  """
  @spec unload_module(module()) :: boolean()
  def unload_module(module), do: router_exists?(module) && :router.delete(module)

  @doc """
  Load one route that was previously removed back into the router
  """
  @spec load_route(module(), path()) :: :error | :ok
  def load_route(module, path) do
    with true <- router_exists?(module),
         route when not is_nil(route) <- find_route(module, path) do
      add_route(module, route)
    else
      _ -> :error
    end
  end

  @doc """
  Unload one route from the router
  """
  @spec unload_route(module(), path()) :: :error | :ok
  def unload_route(module, path) do
    with true <- router_exists?(module),
         route when not is_nil(route) <- find_route(module, path) do
      remove_route(module, route)
      :ok
    else
      _ -> :error
    end
  end

  @doc """
  try to match a
  """
  @spec match_route(module(), path()) :: {:ok, match()} | {:error, match_error()}
  def match_route(module, path) do
    case :router.route(module, compile_path(path)) do
      [{:route, destination, params}] ->
        {:ok, destination_with_params(destination, params)}

      [] ->
        {:error, :no_match}

      matches ->
        matches =
          Enum.map(matches, fn {_, destination, params} ->
            destination_with_params(destination, params)
          end)

        {:error, {:multiple_matches, matches}}
    end
  end

  def routes(module) do
    if router_exists?(module) do
      module
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

  defp find_route(module, path) do
    Enum.find(module.__commands(), &(elem(&1, 0) == path))
  end

  defp add_route(module, {path, stopsel, function, assigns}) do
    :router.add(module, compile_path(path), {stopsel, function, Map.new(assigns)})
  end

  defp remove_route(module, {path, stopsel, function, assigns}) do
    :router.remove_path(module, compile_path(path), {stopsel, function, Map.new(assigns)})
  end

  defp compile_path(path) do
    Enum.map(path, fn
      ":" <> param -> {:+, String.to_atom(param)}
      segment -> segment
    end)
  end

  defp destination_with_params({stopsel, function, assigns}, params) do
    {stopsel, function, assigns, Map.new(params)}
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
