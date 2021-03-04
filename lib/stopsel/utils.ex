defmodule Stopsel.Utils do
  @doc """
  Splits a message by spaces or by surrounding nested quotes (`'` and `"`).
  """
  @spec split_message(String.t() | charlist()) :: [String.t()]
  def split_message(message) do
    message
    |> to_charlist()
    |> Enum.chunk_while({nil, []}, &chunk_tokens/2, &handle_rest/1)
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.map(&to_string/1)
  end

  defp chunk_tokens(?\s, {nil, chunk}), do: {:cont, Enum.reverse(chunk), {nil, []}}
  defp chunk_tokens(?', {nil, chunk}), do: {:cont, Enum.reverse(chunk), {?', []}}
  defp chunk_tokens(?", {nil, chunk}), do: {:cont, Enum.reverse(chunk), {?", []}}
  defp chunk_tokens(?', {?', chunk}), do: {:cont, Enum.reverse(chunk), {nil, []}}
  defp chunk_tokens(?", {?", chunk}), do: {:cont, Enum.reverse(chunk), {nil, []}}

  defp chunk_tokens(other, {separator, chunk}),
    do: {:cont, {separator, [other | chunk]}}

  defp handle_rest({last, rest}), do: {:cont, Enum.reverse(rest), {last, []}}
end
