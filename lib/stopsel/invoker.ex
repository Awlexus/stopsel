defmodule Stopsel.Invoker do
  alias Stopsel.{Message, Router}

  def invoke(message, router, prefix \\ "") do
    message = Message.Protocol.to_message(message)

    with true <- String.starts_with?(message.message, prefix),
         {:ok, {stopsel, function, assigns, params}} <-
           Router.match_route(router, parse_path(message, prefix)) do
      message
      |> Message.assign(assigns)
      |> Message.put_params(params)
      |> apply_stopsel(stopsel)
      |> do_invoke(function)
    end
  end

  defp parse_path(%Message{message: message}, prefix) do
    message
    |> String.trim_leading(prefix)
    |> String.trim_leading()
    |> String.split(~r/["']/, trim: true)
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {part, index} when rem(index, 2) == 1 -> [part]
      {part, _} -> String.split(part)
    end)
  end

  defp apply_stopsel(message, stopsel) do
    Enum.reduce_while(stopsel, message, fn
      _, %Message{halted?: true} = message ->
        {:halt, message}

      {function, config}, message when is_function(function) ->
        {:cont, function.(message, config)}

      {module, opts}, message when is_atom(module) ->
        config = module.init(opts)
        {:cont, module.call(message, config)}
    end)
  end

  defp do_invoke(%Message{halted?: true}, _), do: :halted
  defp do_invoke(%Message{} = message, function), do: function.(message, message.params)
end
