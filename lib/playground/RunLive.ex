defmodule Concaveman.RunLive do
  use Phoenix.LiveView
  import Concaveman.Geometry
  alias Concaveman.GeoJSONStore

  def mount(_params, _session, socket) do
    IO.puts("mount")
    IO.inspect(convex_hull([{0, 0}]), label: "convex_hull")
    {:ok, assign(socket, count: 0, svg_content: nil, concavity_value: 2.0, length_value: 0.0)}
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
            this.pushEvent("slider_changed", {id: e.target.id, value: e.target.value});
          });
        }
      };
    </script>

    <script>
      console.log("Goodness from Concaveman.RunLive")
    </script>

    <div class="flex flex-col items-center justify-center min-h-screen">
      <div id="dropzone" phx-hook="DropZone" class="w-[800px] h-[800px] border-2 border-dashed border-gray-300 rounded-lg flex items-center justify-center mb-4">
        <%= if @svg_content do %>
        <%= Phoenix.HTML.raw(@svg_content) %>
        <% else %>
          <p>Drag and drop a GeoJSON file here</p>
        <% end %>
      </div>

      <div class="w-[800px] space-y-4">
        <div>
          <label for="concavity_slider" class="block mb-2">Concavity: <%= @concavity_value %></label>
          <input id="concavity_slider" type="range" min="0" max="10" step="0.1" value={@concavity_value} phx-hook="Slider" class="w-full" />
        </div>
        <div>
          <label for="length_slider" class="block mb-2">Length: <%= @length_value %></label>
          <input id="length_slider" type="range" min="0" max="2" step="0.1" value={@length_value} phx-hook="Slider" class="w-full" />
        </div>
      </div>
    </div>

    <div class="fixed top-4 left-4">
      <span>Count: <%= @count %></span>
      <button phx-click="inc" class="ml-2 px-2 py-1 bg-blue-500 text-white rounded">+</button>
      <button phx-click="dec" class="ml-2 px-2 py-1 bg-red-500 text-white rounded">-</button>
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

    # Parse and store the GeoJSON data in the GeoJSONStore
    parsed_coordinates = parse_geojson(data)
    GeoJSONStore.store(self(), parsed_coordinates)

    # Generate initial SVG
    concavity = socket.assigns.concavity_value
    length = socket.assigns.length_value
    hull = generate_concave_hull(parsed_coordinates, concavity, length)
    # Set to true to render points
    svg = generate_svg(parsed_coordinates, hull, concavity, length, true)

    {:noreply, assign(socket, svg_content: svg)}
  end

  def handle_event("slider_changed", %{"id" => id, "value" => value}, socket) do
    new_value = string_to_number(value)

    {slider_key, concavity, length} =
      case id do
        "concavity_slider" -> {:concavity_value, new_value, socket.assigns.length_value}
        "length_slider" -> {:length_value, socket.assigns.concavity_value, new_value}
      end

    # Retrieve GeoJSON data from the GeoJSONStore
    geojson_data = GeoJSONStore.retrieve(self())

    # Generate new SVG using stored GeoJSON data and both slider values
    hull = generate_concave_hull(geojson_data, concavity, length)
    # Set to true to render points
    svg = generate_svg(geojson_data, hull, concavity, length, false)

    {:noreply, assign(socket, [{slider_key, new_value}, {:svg_content, svg}])}
  end

  def handle_event(name, params, socket) do
    IO.inspect(name, label: "name")
    IO.inspect(params, label: "params")
    {:noreply, socket}
  end

  defp parse_geojson(data) do
    case data do
      %{"type" => "FeatureCollection", "features" => features} ->
        features
        |> Enum.flat_map(&extract_polygon_coordinates/1)

      %{"type" => "Feature", "geometry" => geometry} ->
        extract_polygon_coordinates(%{"geometry" => geometry})

      %{"type" => geometry_type} when geometry_type in ["Polygon", "MultiPolygon"] ->
        extract_polygon_coordinates(%{"geometry" => data})

      coordinates when is_list(coordinates) ->
        coordinates
        |> Enum.map(fn
          [x, y] when is_number(x) and is_number(y) -> {x, y}
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  end

  defp string_to_number(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} ->
        number

      {number, _} ->
        number

      :error ->
        case Integer.parse(value) do
          {number, ""} -> number / 1
          {number, _} -> number / 1
          :error -> 0.0
        end
    end
  end

  defp string_to_number(value) when is_number(value), do: value
  defp string_to_number(_), do: 0.0

  defp extract_polygon_coordinates(feature) do
    case feature do
      %{"geometry" => %{"type" => "Polygon", "coordinates" => coordinates}} ->
        coordinates
        |> List.flatten()
        |> Enum.chunk_every(2)
        |> Enum.map(fn [x, y] -> {x, y} end)

      %{"geometry" => %{"type" => "MultiPolygon", "coordinates" => coordinates}} ->
        coordinates
        |> List.flatten()
        |> Enum.chunk_every(2)
        |> Enum.map(fn [x, y] -> {x, y} end)

      %{"geometry" => %{"type" => type, "coordinates" => coordinates}}
      when type in ["Point", "LineString"] ->
        coordinates
        |> List.wrap()
        |> List.flatten()
        |> Enum.chunk_every(2)
        |> Enum.map(fn [x, y] -> {x, y} end)

      _ ->
        []
    end
  end

  @type point :: {number(), number()}
  @type points :: [point]
  @type concavity :: number()
  @type length_threshold :: number()

  @spec generate_concave_hull(points, concavity, length_threshold) :: points
  defp generate_concave_hull(points, concavity, length_threshold) do
    {convex_hull_time, hull} =
      :timer.tc(fn ->
        points |> Concaveman.Geometry.fast_convex_hull()
      end)

    {concave_hull_time, concave_hull} =
      :timer.tc(fn ->
        Concaveman.Native.concaveman(points, hull, concavity, length_threshold)
      end)

    IO.puts("Convex hull calculation time: #{convex_hull_time / 1000} ms")
    IO.puts("Concave hull calculation time: #{concave_hull_time / 1000} ms")

    concave_hull
  end

  defp generate_svg(geojson_data, hull, concavity, length, render_points \\ false)
       when is_list(geojson_data) and length(geojson_data) > 0 do
    # Calculate the bounding box of the data
    {{min_x, _}, {max_x, _}} = Enum.min_max_by(geojson_data, fn {x, _} -> x end)
    {{_, min_y}, {_, max_y}} = Enum.min_max_by(geojson_data, fn {_, y} -> y end)

    # Calculate the scale and offset to fit the data in the SVG
    width = 800
    height = 800
    padding = 20

    scale =
      min(
        (width - 2 * padding) / (max_x - min_x),
        (height - 2 * padding) / (max_y - min_y)
      )

    # Create the path data
    path_data =
      hull
      |> Enum.map_join(" ", fn {x, y} ->
        sx = (x - min_x) * scale + padding
        # Flip Y-axis
        sy = height - ((y - min_y) * scale + padding)
        "#{sx},#{sy}"
      end)

    # Generate points as SVG circles if render_points is true
    points_svg =
      if render_points do
        geojson_data
        |> Enum.map(fn {x, y} ->
          sx = (x - min_x) * scale + padding
          sy = height - ((y - min_y) * scale + padding)
          ~s(<circle cx="#{sx}" cy="#{sy}" r="2" fill="red" />)
        end)
        |> Enum.join("\n")
      else
        ""
      end

    # Generate the SVG
    """
    <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
      <path d="M #{path_data} Z" fill="none" stroke="black" stroke-width="1" />
      #{points_svg}
      <text x="10" y="20" font-family="Verdana" font-size="12" fill="black">
        Concavity: #{concavity}, Length: #{length}, Points: #{length(geojson_data)} Hull: #{length(hull)}
      </text>
    </svg>
    """
  end

  defp generate_svg(_geojson_data, _hull, _concavity, _length, _render_points) do
    """
    <svg width="800" height="800" xmlns="http://www.w3.org/2000/svg">
      <text x="10" y="50" font-family="Verdana" font-size="12" fill="black">
        No valid GeoJSON data available
      </text>
    </svg>
    """
  end

  def terminate(_reason, _socket) do
    GeoJSONStore.store(self(), nil)
  end
end
