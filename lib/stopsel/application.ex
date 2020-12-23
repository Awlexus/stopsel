defmodule Stopsel.Application do
  @moduledoc false

  use Application

  def start(_, _) do
    children = [
      Stopsel.Router
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
