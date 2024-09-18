defmodule ConcavemanTest do
  use ExUnit.Case
  doctest Concaveman

  alias Concaveman.Geometry
  alias ConcavemanTest.SVGHelpers

  @fixtures_path Path.join(__DIR__, "fixtures")
  defp fixture_path(name), do: Path.join(@fixtures_path, name)

  defp read_points_fixture(name) do
    fixture_path("#{name}.json")
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn [x, y] -> {x, y} end)
  end

  defp read_geojson_fixture(name) do
    fixture_path("#{name}.json")
    |> File.read!()
    |> Jason.decode!()
    |> Concaveman.Utils.parse_geojson()
  end

  test "it" do
    # points = [{0, 0}, {1, 0}, {0.25, 0.25}, {1, 1}]
    # hull = [0, 1, 3]
    # Concaveman.Native.concaveman(points, hull, 2.0, 1)

    points = [{0.0, 0.0}, {0.25, 0.15}, {1.0, 0.0}, {1.0, 1.0}]
    hull = [0, 2, 3]
    concavity = 2.0
    length_threshold = 0.0

    result = Concaveman.Native.concaveman(points, hull, concavity, length_threshold)
    IO.inspect(result)
  end

  test "render points as SVG" do
    points = read_points_fixture("points-1k")

    svg = SVGHelpers.points_to_svg(points)

    # You can write the SVG to a file for visual inspection
    fixture_path("points-1k.svg") |> File.write!(svg)
  end

  test "render hull as SVG" do
    filename = "points-1k-hull"

    points = read_points_fixture(filename)

    svg = SVGHelpers.hull_to_svg(points)

    # You can write the SVG to a file for visual inspection
    fixture_path("#{filename}.svg") |> File.write!(svg)
  end

  test "convex_hull as SVG" do
    points = read_points_fixture("points-1k")

    hull = Geometry.convex_hull(points)

    svg = SVGHelpers.hull_to_svg(hull)

    fixture_path("points-1k-slow-convex_hull.svg") |> File.write!(svg)
  end

  test "fast_convex_hull as SVG" do
    points = read_points_fixture("points-1k")

    hull = Geometry.fast_convex_hull(points)

    svg = SVGHelpers.hull_to_svg(hull)

    fixture_path("points-1k-fast-convex_hull.svg") |> File.write!(svg)
  end

  test "concaveman as SVG" do
    points = read_points_fixture("points-1k")

    hull = Geometry.fast_convex_hull(points)

    concavity = 3.0
    length_threshold = 0.1

    result = Concaveman.Native.concaveman(points, hull, concavity, length_threshold)

    svg = SVGHelpers.hull_to_svg(result)

    fixture_path("points-1k-concaveman.svg") |> File.write!(svg)
  end

  test "random points" do
    # Set a specific seed for reproducibility
    :rand.seed(:exsss, {1234, 5678, 9012})

    length_threshold = 0.1

    points = for _ <- 1..500, do: {:rand.uniform(), :rand.uniform()}
    hull = Geometry.fast_convex_hull(points)
    svg = SVGHelpers.points_and_hull_to_svg(points, hull)
    fixture_path("random-points-hull.svg") |> File.write!(svg)

    concavity = 0.7

    result = Concaveman.Native.concaveman(points, hull, concavity, length_threshold)
    svg = SVGHelpers.points_and_hull_to_svg(points, result)
    fixture_path("random-points-concaveman-#{concavity}.svg") |> File.write!(svg)

    concavity = 2.0

    result = Concaveman.Native.concaveman(points, hull, concavity, length_threshold)
    svg = SVGHelpers.points_and_hull_to_svg(points, result)
    fixture_path("random-points-concaveman-#{concavity}.svg") |> File.write!(svg)

    concavity = 1.0

    result = Concaveman.Native.concaveman(points, hull, concavity, length_threshold)
    svg = SVGHelpers.points_and_hull_to_svg(points, result)
    fixture_path("random-points-concaveman-#{concavity}.svg") |> File.write!(svg)
  end

  test "large number of points" do
    points = read_geojson_fixture("2183131_11c4514160167a0d_mid-devon")
    hull = Geometry.fast_convex_hull(points)

    result = Concaveman.Native.concaveman(points, hull, 2.0, 0.0)

    IO.puts("points: #{length(points)}")
    IO.puts("hull: #{length(hull)}")
    IO.puts("result: #{length(result)}")
  end
end
