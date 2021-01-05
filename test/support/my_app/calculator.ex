defmodule MyApp.Calculator do
  def add(_message, %{a: a, b: b}) do
    IO.puts("#{a} + #{b} = #{a + b}")
  end

  def subtract(_message, %{a: a, b: b}) do
    IO.puts("#{a} - #{b} = #{a - b}")
  end

  def multiply(_message, %{a: a, b: b}) do
    IO.puts("#{a} * #{b} = #{a * b}")
  end

  def divide(_message, %{a: a, b: b}) do
    IO.puts("#{a} / #{b} = #{a / b}")
  end
end
