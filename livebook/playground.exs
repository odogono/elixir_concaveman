Mix.install([
    {:phoenix_playground, "~> 0.1.6"},
    {:concaveman, path: "..", env: :dev, app: false}
  ],
  lockfile: "mix.lock"
  )

  defmodule RunLive do
    use Phoenix.LiveView
    import Concaveman.Geometry

    def mount(_params, _session, socket) do
      IO.puts("mount")
      IO.inspect(convex_hull([{0, 0}]), "convex_hull")
      {:ok, assign(socket, count: 0)}
    end

    def render(assigns) do
      ~H"""
      <script src="https://cdn.tailwindcss.com"></script>
      <div class="flex justify-center items-center h-screen bg-black">
      <span>Count: <%= @count %></span>
      <button phx-click="inc">+</button>
      <button phx-click="dec">-</button>
      </div>
      """
    end

    def handle_event("inc", _params, socket) do
      {:noreply, update(socket, :count, &(&1 + 1))}
    end

    def handle_event("dec", _params, socket) do
      {:noreply, update(socket, :count, &(&1 - 1))}
    end
  end

  PhoenixPlayground.start(live: RunLive)
