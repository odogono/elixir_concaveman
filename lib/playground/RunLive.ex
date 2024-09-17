defmodule Concaveman.RunLive do
  use Phoenix.LiveView
  import Concaveman.Geometry

  def mount(_params, _session, socket) do
    IO.puts("mount")
    IO.inspect(convex_hull([{0, 0}]), label: "convex_hull")
    {:ok, assign(socket, count: 0, svg_content: nil, slider_value: 50, geojson_data: nil)}
  end

  def render(assigns) do
    ~H"""
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
      window.hooks.DropZone = {
        mounted() {
          this.el.addEventListener("dragover", (e) => {
            e.preventDefault();
            e.stopPropagation();
          });

          this.el.addEventListener("drop", (e) => {
            e.preventDefault();
            e.stopPropagation();

            const file = e.dataTransfer.files[0];
            const reader = new FileReader();

            reader.onload = (event) => {
              if (event.target && typeof event.target.result === 'string') {
                const data = JSON.parse(event.target.result);
                console.log('hey data', data);
                this.pushEventTo("#dropzone", "geojson_dropped", {data});
              }
            };

            reader.readAsText(file);
          });
        }
      };

      window.hooks.Slider = {
        mounted() {
          this.el.addEventListener("input", (e) => {
            this.pushEvent("slider_changed", {value: e.target.value});
          });
        }
      };
    </script>

    <script>
      console.log("Goodness from Concaveman.RunLive")
    </script>

    <span>Ooo Count: <%= @count %></span>
    <button phx-click="inc">+</button>
    <button phx-click="dec">-</button>

    <div class="flex justify-center items-center min-h-screen">
      <div id="dropzone" phx-hook="DropZone" class="w-[800px] h-[800px] border-2 border-dashed border-gray-300 rounded-lg flex items-center justify-center">
        <%= if @svg_content do %>
        <%= Phoenix.HTML.raw(@svg_content) %>
        <% else %>
          <p>Drag and drop a GeoJSON file here</p>
        <% end %>
      </div>
    </div>

    <div class="mt-4">
      <label for="slider">Concavity: <%= @slider_value %></label>
      <input id="slider" type="range" min="0" max="100" value={@slider_value} phx-hook="Slider" />
    </div>
    """
  end

  def handle_event("inc", _params, socket) do
    IO.puts("inc to #{socket.assigns.count + 2} ok!")
    {:noreply, update(socket, :count, &(&1 + 2))}
  end

  def handle_event("dec", _params, socket) do
    IO.puts("dec")
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def handle_event("geojson_dropped", %{"data" => data}, socket) do
    IO.inspect(data, label: "GeoJSON data")

    # Parse and store the GeoJSON data
    geojson_data = parse_geojson(data)

    # Generate initial SVG
    svg = generate_svg(geojson_data, socket.assigns.slider_value)

    {:noreply, assign(socket, geojson_data: geojson_data, svg_content: svg)}
  end

  def handle_event("slider_changed", %{"value" => value}, socket) do
    IO.puts("Slider changed to #{value}")
    new_value = String.to_integer(value)

    # Generate new SVG using stored GeoJSON data and new slider value
    svg = generate_svg(socket.assigns.geojson_data, new_value)

    {:noreply, assign(socket, slider_value: new_value, svg_content: svg)}
  end

  def handle_event(name, params, socket) do
    IO.inspect(name, label: "name")
    IO.inspect(params, label: "params")
    {:noreply, socket}
  end

  defp parse_geojson(data) do
    # Here you would implement the logic to parse the GeoJSON data
    # For now, we'll just return the data as-is
    data
  end

  defp generate_svg(nil, _concavity) do
    "No GeoJSON data available"
  end

  defp generate_svg(geojson_data, concavity) do
    # Here you would implement the logic to generate an SVG based on the GeoJSON data and concavity
    # For now, we'll just return a placeholder SVG
    """
    <svg width="100%" height="100%" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <text x="10" y="50" font-family="Verdana" font-size="12" fill="black">
        GeoJSON loaded. Concavity: #{concavity}
      </text>
    </svg>
    """
  end
end
