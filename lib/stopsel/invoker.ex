defmodule Stopsel.Invoker do
  alias Stopsel.{Message, Router}

  require Logger

  def invoke(%Message{} = message, router) do
    with {:ok, {stopsel, function, assigns, params}} <-
           Router.match_route(router, parse_path(message)) do
      message
      |> Message.assign(assigns)
      |> Message.put_params(params)
      |> apply_stopsel(stopsel)
      |> do_invoke(function)
    end
  end

  def invoke(message, router) do
    message = %Message{
      assigns: Message.Protocol.assigns(message),
      content: Message.Protocol.content(message)
    }

    invoke(message, router)
  end

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

  defp parse_path(%Message{content: message}) do
    message
    |> String.split(~r/["']/, trim: true)
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {part, index} when rem(index, 2) == 1 -> [part]
      {part, _} -> String.split(part)
    end)
  end

  defp apply_stopsel(message, stopsel) do
    Enum.reduce_while(stopsel, message, fn
      {function, config}, message when is_function(function) ->
        message = function.(message, config)

        if message.halted? do
          Logger.debug("Halted message in #{inspect(function)}")
          {:halt, message}
        else
          {:cont, message}
        end

      {module, opts}, message when is_atom(module) ->
        config = module.init(opts)
        message = module.call(message, config)

        if message.halted? do
          Logger.debug("Halted message in #{module}")
          {:halt, message}
        else
          {:cont, message}
        end
    end)
  end

  defp do_invoke(%Message{halted?: true}, _), do: :halted

  defp do_invoke(%Message{} = message, function) do
    result = function.(message, message.params)
    Logger.debug("Message handled returned #{inspect(result)}")
    result
  end
end
