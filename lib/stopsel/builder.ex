defmodule Stopsel.Builder do
  @moduledoc """
  DSL to build a Stopsel router.

  A router is declared using the `router/2` macro.
  Within this macro you can declare commands, scopes and `Stopsel`.

  The commands defined in the router will be used to route the messages
  to the appropriate functions defined in other modules, parallely to the
  router module.

  Note: You can only define one router per module and you cannot use
  builder functions outside of the router definition.

  ## Scopes
  A scope encapsulates commands, stopsel from the parent scope.
  The router-declaration acts as the root scope.

  ## Aliasing
  Every scope can add an alias to the scopes and commands within it.
  An alias is a module which implements a command that has been declared
  in the router.

  In the following example the router applies the initial alias `MyApp` and
  the scope adds the alias Commands, resulting in the alias `MyApp.Commands`
  for all commands defined within the scope.

  ```elixir
  router MyApp do
    scope "command", Commands do
      # Define your commands here
    end
  end
  ```

  ## Paths
  A path is a string with segments that are separated with `|`.
  There are 2 types of segments: Static segments and parameters.

  Note: Avoid adding spaces in path segments as they can confuse
  the `Stopsel.Invoker` module.

  ### Static segments
  Text against which the content of a `Stopsel.Message` is matched against.

  ### Parameter
  A parameter segment is defined by prepending `:` in front of the segment name.
  These parameters will be available in the `:params` of the `Stopsel.Message`.

  ## Commands
  A commands is defined with a name and optionally with path and assigns.
  The name of a command must be the name of a function defined in the
  current alias.

  In this example the command `:execute` would be used to execute the function
  `MyApp.Commands.execute/2`

  ```elixir
  router MyApp do
    scope "command", Commands do
      command :execute
    end
  end
  ```

  Similar to scopes you can define a path segment against which the message must
  match against in order to execute the command. By default this will use the
  name of the command, if no path was given.

  Additionally assigns can be added to a command. These will be added to the
  message before any stopsel are applied.

  ## Stopsel
  A stopsel can be defined as a function or a module.
  A message will pass through each of the stopsel that applies to the current
  scope. Each stopsel can edit the message or halt the message from being
  passed down to the command function.

  For more information on stopsel see `Stopsel`
  """

  alias Stopsel.Builder.{Helper, Scope}

  @type do_block :: [do: term()]
  @type stopsel :: module() | atom()
  @type options :: any()
  @type path :: String.t() | nil
  @type assigns :: map() | Keyword.t()
  @type name :: atom()
  @type alias :: module()

  @doc """
  Starts the router definition.

  Optionally a module can be provided to scope all command definitions.
  Note that only one router can be defined per module.
  """
  @spec router(alias() | nil, do_block()) :: Macro.t()
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

  @doc """
  Adds a stopsel to the current scope.

  A stopsel only active after the point it has been declared and does not
  leave its scope. See `Stopsel` for more details.

  Cannot be declared outside of the router.
  """
  @spec stopsel(stopsel(), options()) :: Macro.t()
  defmacro stopsel(stopsel, opts \\ []) do
    quote location: :keep do
      unquote(in_router!({:stopsel, 2}))

      @scope Helper.put_stopsel(@scope, unquote(stopsel), unquote(opts), __ENV__)
    end
  end

  @doc """
  Scopes the stopsel and commands defined within the scope.

  See the section "Paths" for more details on how paths are declared.

  Cannot be declared outside of the router.
  """
  @spec scope(path(), alias() | nil, do_block()) :: Macro.t()
  defmacro scope(path \\ nil, module \\ nil, do: block) do
    quote location: :keep do
      unquote(in_router!({:scope, 3}))

      @scope Helper.push_scope(@scope, unquote(path), unquote(module))
      unquote(block)
      @scope Helper.pop_scope(@scope)
    end
  end

  @doc """
  Adds a command to the router.

  See the section "Paths" for more details on how paths are declared.

  Additionally to the path you can also specify assigns that will be
  added to the message before the stopsel are executed.

  Cannot be declared outside of the router.
  """
  @spec command(name(), path(), assigns()) :: Macro.t()
  defmacro command(name, path \\ nil, assigns \\ []) do
    quote location: :keep do
      unquote(in_router!({:command, 2}))

      @commands Helper.command(
                  @scope,
                  unquote(name),
                  unquote(path),
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
