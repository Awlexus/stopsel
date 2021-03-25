defmodule Stopsel.Builder.Helper do
  @moduledoc false
  alias Stopsel.Command
  alias Stopsel.Builder.Scope

  def put_stopsel([scope | rest], stopsel, opts, env) do
    compiled = compile_stopsel(env, stopsel, opts)
    [%{scope | stopsel: scope.stopsel ++ [compiled]} | rest]
  end

  def push_scope([head | _] = scopes, path, module) do
    new_scope = %Scope{
      path: parse_path(head.path, path),
      stopsel: head.stopsel,
      module: Module.concat(head.module, module)
    }

    [new_scope | scopes]
  end

  def pop_scope([_ | rest]), do: rest

  def command(scopes, name, nil, assigns) do
    command(scopes, name, to_string(name), assigns)
  end

  def command([%Scope{} = scope | _], name, path, assigns) do
    if command_compiled?(scope.module, name, 2) do

      command =
        %Command{
          path: parse_path(scope.path, path),
          stopsel: scope.stopsel,
          module: scope.module,
          function: name,
          assigns: Map.new(assigns)
        }

      command
    else
      IO.warn("#{scope.module}.#{name}/2 does not exist")
      nil
    end
  end

  defp parse_path(prefix, nil), do: prefix
  defp parse_path(prefix, path), do: prefix ++ String.split(path)

  defp compile_stopsel(env, stopsel, opts) do
    with :error <- compile_module_stopsel(stopsel, opts),
         :error <- compile_function_stopsel(env, stopsel, opts) do
      raise Stopsel.InvalidStopsel, stopsel
    end
  end

  defp compile_module_stopsel(stopsel, opts) do
    with {:module, _} <- Code.ensure_compiled(stopsel),
         true <- function_exported?(stopsel, :init, 1),
         true <- function_exported?(stopsel, :call, 2) do
      {stopsel, stopsel.init(opts)}
    else
      _ -> :error
    end
  end

  defp compile_function_stopsel(env, stopsel, opts) do
    modules = for {module, functions} <- env.functions, {^stopsel, 2} <- functions, do: module

    case modules do
      [module] -> {{module, stopsel}, opts}
      _ -> :error
    end
  end

  defp command_compiled?(module, name, arity) do
    case Code.ensure_compiled(module) do
      {:module, ^module} -> function_exported?(module, name, arity)
      _ -> false
    end
  end
end
