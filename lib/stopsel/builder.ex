defmodule Stopsel.Builder do
  alias Stopsel.Builder.{Helper, Scope}

  @type do_block :: [do: term()]
  @type stopsel :: module() | atom()
  @type options :: any()
  @type path :: String.t() | nil
  @type assigns :: map() | Keyword.t()
  @type name :: atom()

  @spec router(module() | nil, do_block()) :: Macro.t()

  defmacro router(module \\ nil, do: block) do
    quote location: :keep do
      # Ensure only one router per module
      if Module.get_attribute(__MODULE__, :router_defined?, false) do
        raise Stopsel.RouterAlreadyDefinedError,
              "The router has already been defined for #{__MODULE__}"
      end

      @in_router? true
      @scope [%Scope{module: unquote(module)}]
      Module.register_attribute(__MODULE__, :commands, accumulate: true, persist: true)

      unquote(block)

      def __commands__(), do: @commands

      @in_router? false
      @router_defined? true
    end
  end

  @spec stopsel(stopsel(), options()) :: Macro.t()
  defmacro stopsel(stopsel, opts \\ []) do
    quote location: :keep do
      unquote(in_router!({:stopsel, 2}))

      @scope Helper.put_stopsel(@scope, unquote(stopsel), unquote(opts), __ENV__)
    end
  end

  @spec scope(path(), module() | nil, do_block()) :: Macro.t()
  defmacro scope(path \\ nil, module \\ nil, do: block) do
    quote location: :keep do
      unquote(in_router!({:scope, 3}))

      @scope Helper.push_scope(@scope, unquote(path), unquote(module))
      unquote(block)
      @scope Helper.pop_scope(@scope)
    end
  end

  @spec command(name(), path(), assigns()) :: Macro.t()
  defmacro command(name, path \\ nil, assigns \\ []) do
    quote location: :keep do
      unquote(in_router!({:command, 2}))

      @commands Helper.command(
                  @scope,
                  unquote(name),
                  unquote(path || to_string(name)),
                  unquote(assigns)
                )
    end
  end

  defp in_router!(function) do
    quote location: :keep do
      unless Module.get_attribute(__MODULE__, :in_router?, false),
        do: raise(Stopsel.OutsideOfRouterError, unquote(function))
    end
  end
end
