defmodule Stopsel.Commands.Calculator do
  import Stopsel.Message

  def add(_message, %{a: a, b: b}) do
    IO.puts(to_string(a + b))
  end

  def subtract(_message, %{a: a, b: b}) do
    IO.puts(to_string(a - b))
  end

  def multiply(_message, %{a: a, b: b}) do
    IO.puts(to_string(a * b))
  end

  def divide(_message, %{a: a, b: b}) do
    IO.puts(to_string(a / b))
  end

  def parse_number(message, param) do
    with {:ok, string} <- Map.fetch(message.params, param),
         :error <- Float.parse(string),
         :error <- Integer.parse(string) do
      IO.puts("Parameter #{inspect(string)} is not a valid number")
      halt(message)
    else
      :error ->
        IO.puts("Parameter #{param} not found")
        halt(message)

      {number, _} ->
        put_param(message, param, number)
    end
  end
end
