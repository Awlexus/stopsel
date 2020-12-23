defmodule Stopsel.Commands do
  def shout(_message, %{rest: rest}) do
    IO.puts String.upcase(rest)
  end
  def whisper(_message, %{rest: rest}) do
    IO.puts "*Softly* #{rest}"
  end
end
