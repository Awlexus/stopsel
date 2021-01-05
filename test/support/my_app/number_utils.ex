defmodule MyApp.NumberUtils do
  alias Stopsel.Message

  def parse_number(%Message{params: params} = message, param_name) do
    with {:ok, param} <- Map.fetch(params, param_name),
         {:ok, number} <- do_parse(param) do
      Message.put_param(message, param_name, number)
    else
      _ -> Message.halt(message)
    end
  end

  defp do_parse(param) do
    with :error <- Integer.parse(param),
         :error <- Integer.parse(param) do
      :error
    else
      {number, _} -> {:ok, number}
    end
  end
end
