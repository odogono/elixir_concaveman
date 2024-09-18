defmodule Concaveman.Utils do
  def parse_geojson(data) do
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

  def string_to_number(value) when is_binary(value) do
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

  def string_to_number(value) when is_number(value), do: value
  def string_to_number(_), do: 0.0

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
end
