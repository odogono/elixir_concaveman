defmodule Concaveman.RouterLive do
  use Phoenix.LiveView
  import Concaveman.Geometry

  def mount(_params, _session, socket) do
    IO.puts("mount")
    IO.inspect(convex_hull([{0, 0}]), label: "convex_hull")
    {:ok, assign(socket, count: 0)}
  end

  def render(assigns) do
    ~H"""

    <script>
      console.log("Goodness from Concaveman.RouterLive")
      window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
        // enable server log streaming to client.
        // disable with reloader.disableServerLogs()
        reloader.enableServerLogs()
      })
    </script>

    <span>Yay Count: <%= @count %></span>
    <button phx-click="inc">+</button>
    <button phx-click="dec">-</button>
    <br/>

    """
  end

  def country(assigns) do
    ~H"""
    The chosen country is: <%= @name %>.
    """
  end

  def handle_event("inc", _params, socket) do
    IO.puts("[Concaveman.RouterLive] inc to #{socket.assigns.count + 2} ok!")
    {:noreply, update(socket, :count, &(&1 + 2))}
  end

  def handle_event("dec", _params, socket) do
    IO.puts("[Concaveman.RouterLive] dec to #{socket.assigns.count - 1}")
    {:noreply, update(socket, :count, &(&1 - 1))}
  end
end

defmodule Concaveman.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  #   embed_templates("error_html/*")

  pipeline :browser do
    plug(:put_root_layout, html: {Concaveman.Layout, :root})
  end

  scope "/" do
    pipe_through(:browser)
    live("/", Concaveman.RouterLive)
  end
end

# defmodule Concaveman.ErrorHTML do
# #   use Concaveman, :html

#   def render(template, _assigns) do
#     Phoenix.Controller.status_message_from_template(template)
#   end
# end

defmodule Concaveman.CodeReloader do
  @moduledoc false

  def reload(_endpoint, _options \\ []) do
    if path = Application.get_env(:phoenix_playground, :file) do
      case File.read(path) do
        {:ok, contents} ->
          IO.puts("Reloading #{path}")
          old = Code.get_compiler_option(:ignore_module_conflict) == true
          Code.put_compiler_option(:ignore_module_conflict, true)
          Code.eval_string(contents, [], file: path)
          Code.put_compiler_option(:ignore_module_conflict, old)

        # ignore fs errors. (Seems like saving file in vim sometimes make it temp dissapear?)
        {:error, _reason} ->
          IO.puts("Error reloading #{path}")
          :ok
      end
    else
      # in Livebook, path is nil
      :ok
    end
  end
end

# defimpl Plug.Exception, for: Concaveman.Customerror do
#     def status(_exception), do: 500
# end

defmodule Concaveman.Endpoint do
  use Phoenix.Endpoint, otp_app: :concaveman
  plug(Plug.Logger)
  socket("/live", Phoenix.LiveView.Socket)
  plug(Plug.Static, from: {:phoenix, "priv/static"}, at: "/assets/phoenix")
  plug(Plug.Static, from: {:phoenix_live_view, "priv/static"}, at: "/assets/phoenix_live_view")
  socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
  plug(Phoenix.LiveReloader)
  plug(Phoenix.CodeReloader, reloader: &Concaveman.CodeReloader.reload/2)
  plug(Concaveman.Router)
end
