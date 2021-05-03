defmodule Stopsel.Invoker do
  @moduledoc """
  Routes a message through a router.

  This module relies on `Stopsel.Router` for matching the routes,
  which ensures that only active routes will be tried to match against.
  """
  alias Stopsel.{Command, Message, Router, Utils}

  require Logger

  @type reason :: Router.match_error() | {:halted, Message.t()}
  @type prefix_error :: :wrong_prefix

  @doc """
  Tries to match a message against the loaded routes of the specified router.
  The message can either be a `Stopsel.Message` struct or any data structure
  that implements `Stopsel.Message.Protocol`.

  ### Return values
  This function will return either `{:ok, value}` or `{:error, reason}`

  The `value` in `{:ok, value}` is the result of the executed command.

  The `reason` in `{:error, reason}` can be one of the following values
  * `:no_match` - No matching route was found for the message
  * `{:multiple_matches, matches}` - Multiple matching routes where found for
    the message. This should be avoided.
  * `{:halted, message}` - The message was halted in the pipeline.

  ```elixir
  iex> import ExUnit.CaptureIO
  iex> Stopsel.Router.load_router(MyApp.Router)
  true
  iex> capture_io(fn -> Stopsel.Invoker.invoke("hello", MyApp.Router) end)
  "Hello world!\\n"
  iex> Stopsel.Invoker.invoke("helloooo", MyApp.Router)
  {:error, :no_match}
  ```

  Only loaded routes will be found.

      iex> Stopsel.Router.load_router(MyApp.Router)
      true
      iex> Stopsel.Router.unload_route(MyApp.Router, ~w"hello")
      iex> Stopsel.Invoker.invoke("hello", MyApp.Router)
      {:error, :no_match}

  """
  @spec invoke(Message.t() | term(), Router.router()) ::
          {:ok, term} | {:error, reason()}
  def invoke(%Message{} = message, router) do
    with {:ok, %Command{} = command} <-
           Router.match_route(router, parse_path(message)) do
      %{message | rest: command.rest}
      |> Message.assign(command.assigns)
      |> Message.put_params(command.params)
      |> apply_stopsel(command.stopsel)
      |> case do
        %Message{halted?: true} = message ->
          {:error, {:halted, message}}

        %Message{} = message ->
          {:ok, do_invoke(message, command.module, command.function)}

        other ->
          raise Stopsel.InvalidMessage, other
      end
    end
  end

  def invoke(message, router) do
    message = %Message{
      assigns: Message.Protocol.assigns(message),
      content: Message.Protocol.content(message),
      params: Message.Protocol.params(message)
    }

    invoke(message, router)
  end

  @doc """
  Same as `invoke/2` but also checks that the message starts with the
  specified prefix.

  Returns `{:error, :wrong_prefix}` otherwise.

      iex> import ExUnit.CaptureIO
      iex> Stopsel.Router.load_router(MyApp.Router)
      true
      iex> capture_io(fn ->
      ...>   assert {:ok, :ok} == Stopsel.Invoker.invoke("!hello", MyApp.Router, "!")
      ...> end)
      "Hello world!\\n"
      iex> capture_io(fn ->
      ...>  assert {:ok, :ok} == Stopsel.Invoker.invoke("!   hello", MyApp.Router, "!")
      ...> end)
      "Hello world!\\n"

  """
  @spec invoke(Message.t() | term(), Router.router(), String.t()) ::
          {:ok, term} | {:error, reason() | prefix_error()}
  def invoke(message, router, ""), do: invoke(message, router)
  def invoke(message, router, nil), do: invoke(message, router)

  def invoke(%Message{} = message, router, prefix) do
    with {:ok, message} <- check_prefix(message, prefix) do
      invoke(message, router)
    end
  end

  def invoke(message, router, prefix) do
    message = %Message{
      assigns: Message.Protocol.assigns(message),
      content: Message.Protocol.content(message)
    }

    invoke(message, router, prefix)
  end

  defp check_prefix(message, prefix) do
    if String.starts_with?(message.content, prefix) do
      new_message =
        Map.update!(message, :content, fn message ->
          message
          |> String.trim_leading(prefix)
          |> String.trim_leading()
        end)

      {:ok, new_message}
    else
      {:error, :wrong_prefix}
    end
  end

  defp parse_path(%Message{content: content}) do
    try do
      OptionParser.split(content)
    rescue
      _ -> Utils.split_message(content)
    end
  end

  defp apply_stopsel(message, stopsel) do
    Enum.reduce_while(stopsel, message, fn
      {{module, function}, config}, message ->
        module
        |> apply(function, [message, config])
        |> handle_message(function)

      {module, opts}, message ->
        config = module.init(opts)

        message
        |> module.call(config)
        |> handle_message(module)
    end)
  end

  defp handle_message(%Message{} = message, cause) do
    if message.halted? do
      Logger.debug("Halted message in #{cause}")
      {:halt, message}
    else
      {:cont, message}
    end
  end

  defp handle_message(other, _), do: raise(Stopsel.InvalidMessage, other)

  defp do_invoke(%Message{halted?: true} = message, _, _), do: message

  defp do_invoke(%Message{} = message, module, function) do
    result = apply(module, function, [message, message.params])
    Logger.debug("Message handled returned #{inspect(result)}")
    result
  end
end
