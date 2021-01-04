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

  # All of our commands are defined within this router block
  # "MyApp" will be the base scope of all of our commands
  router MyApp do
    # This defines then command hello. Defining the command
    # ":hello" here demands that the function &MyApp.hello/2
    # exists.

    # This command will match against the text-message "hello"
    command :hello

    # We can scope out commands using a path or even under
    # another module. In this case all following commands
    # will be defined under the path "calculator|:a" and
    # under the module "MyApp.Calculator".

    # Segments of a command are seperated with "|".
    # A segment that starts with ":" will not be used as
    # Text to match against, but as a parameter that will
    # we can use later on.

    scope "calculator|:a", Calculator do
      # A stopsel is similar to a plug.

      # If you are not familiar with the library plug, a
      # "plug" is a module or a function that your request.
      # In this case the text message runs through,
      # before the matching command will be executed.

      # Stopsel generally expect a module or the name of an
      # imported function.
      stopsel :parse_number, :a
      stopsel :parse_number, :b

      # Here we aliased the command to not match against
      # "add", "subtract", ... but against "+", "-", ...
      # and have an aditional parameter called "b"
      command :add, "+|:b"
      command :subract, "-|:b"
      command :multiply, "*|:b"
      command :divide, "/|:b"
    end
  end
end
```

## Implementing the command

Every command defined must be defined as a function in the currently scoped Module. Here's how the commands for `MyApp` could be implemented.

```elixir
defmodule MyApp do
  def hello(_message, _params) do
    IO.puts "Hello world!"
  end
end
```

As mentioned above, a function must be a function that accepts 2 arguments: message, a `Stopsel.Message` struct, and parameters, a map that contains the parameters defined in the  router.

In the example above we have created a route like this.
```elixir
scope "calculator|:a", Calculator do
  command :add, "+|:b"
  ...
end
```

We therefore have a guarantee that the parameters `:a` and `:b` are valid parameters when our command `:add` is called.
So we could define `MyApp.Calculator.add/2` like this

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
The `Stopsel.Router` module allows you to disable routes or the whole router at runtine.

```elixir
# First we need to load the router
iex> Stopsel.Router.load_module(MyApp.Router)
:ok

# Then we can disable routes from the router
iex> Stopsel.Router.unload_route(MyApp.Router, ~w"hello")
:ok

# or enable it again
iex> Stopsel.Router.load_route(MyApp.Router, ~w"hello")
:ok

# and unload our router
iex> Stopsel.Router.unload_module(MyApp.Router)
:ok
```

## Stopsel.Invoker
After all this, let's route out messages!

The module `Stopsel.Invoker` allows us to route our messages through our defined routers. Our Router must be loaded with the `Stopsel.Router` for the this to work.

```elixir
iex> Stopsel.Router.load_module(MyApp.Router)
:ok

# A message can either be a %Stopsel.Message{} or
# anything implements the `Stopsel.Message.Protocol`.
# Strings implement this protocol
iex> Stopsel.Invoker.invoke("hello", MyApp.Router)
"Hello world!"
:ok

iex> Stopsel.Invoker.invoke(%Stopsel.Message{content: "hello"}, MyApp.Router)
"Hello world!"
:ok

# When no route matches
iex> Stopsel.Invoker.invoke("helloooo", MyApp.Router)
{:error, :no_match}

# A prefix can also be used
iex> Stopsel.Invoker.invoke("!hello", MyApp.Router, "!")
"Hello world!"
:ok

# When the prefix doesn't match
iex> Stopsel.Invoker.invoke("hello", MyApp.Router, "!")
{:error, :wrong_prefix}
```