# Stopsel

A library inspired by [plug](https://hex.pm/packages/plug) and [phoenix routers](https://hex.pm/packages/phoenix) for parsing text messages like commands.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `stopsel` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:stopsel, "~> 0.1.0"}
  ]
end
```

## Define a router
Stopsel tries to be lightweight with its usage of Macros. Just import `Stopsel.Builder` and start defining your router.

```elixir
defmodule MyApp.Router do
  import Stopsel.Builder
  import MyApp.NumberUtils,
    only: [parse_number: 2],
    warn: false

  # All of our commands are defined within this router block "MyApp" will
  # be the initial scope of all of our commands.
  router MyApp do

    # This defines the command "hello".
    # Defining the command ":hello" here aliases the command under the
    # module "MyApp" and demands that the function "&MyApp.hello/2" exists.

    # This command will match against the text-message "hello"
    command :hello

    # We can scope commands using a path and alias them further.
    # In this case all following commands will be defined under the path
    # "calculator|:a" and aliased to the module "MyApp.Calculator".

    # Segments of a command path are seperated with "|".
    # A segment that starts with ":" will not be used as Text to match
    # against, but as a parameter that will we can use later on.

    scope "calculator|:a", Calculator do
      # A stopsel is similar to a plug.

      # If you are not familiar with the library plug, a "plug" is a module
      # or a function that your request will pass through. In this case the
      # text message runs through the plug "parse_message" twice, with different
      # configurations, before the matching command will be executed.

      # A stopsel generally expects a module or the name of an imported function.
      stopsel :parse_number, :a
      stopsel :parse_number, :b

      # Here we aliased the commands to not match against "add", "subtract", ...
      # but against "+", "-", ... and have an aditional parameter called "b"
      command :add, "+|:b"
      command :subract, "-|:b"
      command :multiply, "*|:b"
      command :divide, "/|:b"
    end
  end
end
```

## Implementing the command

Every command defined must be defined as a function in the currently aliased Module. Here's how the commands for `MyApp` could be implemented.

```elixir
defmodule MyApp do
  def hello(_message, _params) do
    IO.puts "Hello world!"
  end
end
```

As seen above, a function that handles a command must accept 2 arguments
* A message (`Stopsel.Message` struct)
* a map that contains the parameters defined for the matched route.

In the example above we have created a route like this.
```elixir
scope "calculator|:a", Calculator do
  command :add, "+|:b"
  ...
end
```

We therefore have a guarantee that the parameters `:a` and `:b` are valid parameters when our command `:add` is called.
So we can match against them directly when defining `MyApp.Calculator.add/2`.

```elixir
defmodule MyApp.Calculator do
  # Note: we can assume that a and b are valid numbers,
  # because we added the stopsel `parse_number`.
  def add(_message, %{a: a, b: b}) do
    IO.puts("#{a} + #{b} = #{a + b}")
  end
end
```

## Stopsel message

A `Stopsel.Message` resembles a `Plug.Conn`. It has assigns and parameters that we can use in our plugs and commands.

## Stopsel.Router
The `Stopsel.Router` module allows you to (un)load a router or (un)load routes at runtime.

```elixir
# First we load the router
iex> Stopsel.Router.load_router(MyApp.Router)
:ok

# Then we can disable routes from the router
iex> Stopsel.Router.unload_route(MyApp.Router, ~w"hello")
:ok

# or enable them again
iex> Stopsel.Router.load_route(MyApp.Router, ~w"hello")
:ok

# and unload our router
iex> Stopsel.Router.unload_router(MyApp.Router)
:ok
```

## Stopsel.Invoker
After all this, let's route out messages!

`Stopsel.Invoker` allows us to route our messages through our defined routers.
The invoker will also consider which routes are load/unloaded and respond accordingly.

```elixir
iex> Stopsel.Router.load_router(MyApp.Router)
:ok

# A message can either be a %Stopsel.Message{} or
# anything implements the `Stopsel.Message.Protocol`.
# Strings implement this protocol
iex> Stopsel.Invoker.invoke("hello", MyApp.Router)
"Hello world!"
{:ok, :ok}

iex> Stopsel.Invoker.invoke(%Stopsel.Message{content: "hello"}, MyApp.Router)
"Hello world!"
{:ok, :ok}

# When no route matches
iex> Stopsel.Invoker.invoke("helloooo", MyApp.Router)
{:error, :no_match}

# A prefix can also be used
iex> Stopsel.Invoker.invoke("!hello", MyApp.Router, "!")
"Hello world!"
{:ok, :ok}

# When the prefix doesn't match
iex> Stopsel.Invoker.invoke("hello", MyApp.Router, "!")
{:error, :wrong_prefix}
```

### Roadmap
* [ ] Improve documentation (ongoing effort)
* [ ] Add Tests
* [ ] Improve invoker message parsing
* [ ] Do not use captured functions internally for routes
* [ ] Turn routes into structs
* [ ] Add attributes to scopes and commands such as help descriptions
* [ ] Make it possible to use locally defined functions for stopsel
* [ ] Make it possible to use functions from aliased modules for stopsel
* [ ] Find a way to avoid warnings from imported functions that are used as stopsel
* [ ] Remove dependency `:router`