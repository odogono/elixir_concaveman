defmodule ConcavemanTest do
  use ExUnit.Case
  doctest Concaveman

  alias Concaveman.Geometry

  @fixtures_path Path.join(__DIR__, "fixtures")
  defp fixture_path(name), do: Path.join(@fixtures_path, name)

  defp points_and_hull_to_svg(points, hull, width \\ 500, height \\ 500) do
    svg_points = points_to_svg(points, width, height)
    svg_hull = hull_to_svg(hull, width, height)

    # Create the SVG
    """
    <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
      #{svg_points}
      #{svg_hull}
    </svg>
    """
  end

  defp points_to_svg(points, width \\ 500, height \\ 500) do
    # Find min and max values for x and y
    {min_x, max_x} = Enum.min_max_by(points, fn {x, _} -> x end)
    {min_y, max_y} = Enum.min_max_by(points, fn {_, y} -> y end)

    {min_x, _} = min_x
    {max_x, _} = max_x
    {_, min_y} = min_y
    {_, max_y} = max_y

    # Calculate scaling factors
    scale_x = (width - 20) / (max_x - min_x)
    scale_y = (height - 20) / (max_y - min_y)

    # Generate SVG points
    svg_points =
      points
      |> Enum.map(fn {x, y} ->
        x_scaled = (x - min_x) * scale_x + 10
        y_scaled = height - ((y - min_y) * scale_y + 10)
        ~s(<circle cx="#{x_scaled}" cy="#{y_scaled}" r="3" fill="yellow" />)
      end)
      |> Enum.join("\n")

    svg_points
  end

  def hull_to_svg(points, width \\ 500, height \\ 500) do
    # Find min and max values for x and y
    {min_x, max_x} = Enum.min_max_by(points, fn {x, _} -> x end)
    {min_y, max_y} = Enum.min_max_by(points, fn {_, y} -> y end)

    {min_x, _} = min_x
    {max_x, _} = max_x
    {_, min_y} = min_y
    {_, max_y} = max_y

    # Calculate scaling factors
    scale_x = (width - 20) / (max_x - min_x)
    scale_y = (height - 20) / (max_y - min_y)

    # Generate an SVG Path
    svg_path =
      points
      |> Enum.reduce("", fn
        {x, y}, "" ->
          x_scaled = (x - min_x) * scale_x + 10
          y_scaled = height - ((y - min_y) * scale_y + 10)
          "M#{x_scaled},#{y_scaled}"

        {x, y}, acc ->
          x_scaled = (x - min_x) * scale_x + 10
          y_scaled = height - ((y - min_y) * scale_y + 10)
          "#{acc} L#{x_scaled},#{y_scaled}"
      end)

    "<path d=\"#{svg_path} Z\" stroke=\"white\" fill=\"none\" />"
  end

  defp read_points_fixture(name) do
    fixture_path("#{name}.json")
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn [x, y] -> {x, y} end)
  end

  test "it" do
    # assert Concaveman.hello() == :world

    points = [{0, 0}, {1, 0}, {0.25, 0.25}, {1, 1}]
    hull = [0, 1, 3]

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

    svg = points_to_svg(points)

    # You can write the SVG to a file for visual inspection
    fixture_path("points-1k.svg") |> File.write!(svg)
  end

  test "render hull as SVG" do
    filename = "points-1k-hull"

    points = read_points_fixture(filename)

    svg = hull_to_svg(points)

    # You can write the SVG to a file for visual inspection
    fixture_path("#{filename}.svg") |> File.write!(svg)
  end

  test "convex_hull as SVG" do
    points = read_points_fixture("points-1k")

    hull = Geometry.convex_hull(points)

    svg = hull_to_svg(hull)

    fixture_path("points-1k-slow-convex_hull.svg") |> File.write!(svg)
  end

  test "fast_convex_hull as SVG" do
    points = read_points_fixture("points-1k")

    hull = Geometry.fast_convex_hull(points)

    svg = hull_to_svg(hull)

    fixture_path("points-1k-fast-convex_hull.svg") |> File.write!(svg)
  end

  test "concaveman as SVG" do
    points = read_points_fixture("points-1k")

    hull = Geometry.fast_convex_hull(points)

    concavity = 3.0
    length_threshold = 0.1

    result = Concaveman.Native.concaveman(points, hull, concavity, length_threshold)

    svg = hull_to_svg(hull)

    fixture_path("points-1k-concaveman.svg") |> File.write!(svg)
  end

  test "random points" do
    # Set a specific seed for reproducibility
    :rand.seed(:exsss, {1234, 5678, 9012})

    length_threshold = 0.1

    points = for _ <- 1..500, do: {:rand.uniform(), :rand.uniform()}
    hull = Geometry.fast_convex_hull(points)
    svg = points_and_hull_to_svg(points, hull)
    fixture_path("random-points-hull.svg") |> File.write!(svg)

    concavity = 0.7

    result = Concaveman.Native.concaveman(points, hull, concavity, length_threshold)
    svg = points_and_hull_to_svg(points, result)
    fixture_path("random-points-concaveman-#{concavity}.svg") |> File.write!(svg)

    concavity = 2.0

    result = Concaveman.Native.concaveman(points, hull, concavity, length_threshold)
    svg = points_and_hull_to_svg(points, result)
    fixture_path("random-points-concaveman-#{concavity}.svg") |> File.write!(svg)

    concavity = 1.0

    result = Concaveman.Native.concaveman(points, hull, concavity, length_threshold)
    svg = points_and_hull_to_svg(points, result)
    fixture_path("random-points-concaveman-#{concavity}.svg") |> File.write!(svg)
  end
end
