defmodule Concaveman.Application do
  use Application

  def start(_type, _args) do
    children = [
      {PhoenixPlayground, options()}
    ]

    opts = [strategy: :one_for_one, name: Concaveman.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp options() do
    [
      #   endpoint: Concaveman.Endpoint,
      live: Concaveman.RunLive,
      live_reload: true,
      file: "lib/playground/RunLive.ex"
    ]
  end
end
