defmodule ConcavemanTest.SVGHelpers do
  def points_and_hull_to_svg(points, hull, width \\ 500, height \\ 500) do
    svg_points = points_to_svg(points, width, height)
    svg_hull = hull_to_svg(hull, width, height)

    """
    <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
      #{svg_points}
      #{svg_hull}
    </svg>
    """
  end

  def points_to_svg(points, width \\ 500, height \\ 500) do
    {min_x, max_x} = Enum.min_max_by(points, fn {x, _} -> x end)
    {min_y, max_y} = Enum.min_max_by(points, fn {_, y} -> y end)

    {min_x, _} = min_x
    {max_x, _} = max_x
    {_, min_y} = min_y
    {_, max_y} = max_y

    scale_x = (width - 20) / (max_x - min_x)
    scale_y = (height - 20) / (max_y - min_y)

    points
    |> Enum.map(fn {x, y} ->
      x_scaled = (x - min_x) * scale_x + 10
      y_scaled = height - ((y - min_y) * scale_y + 10)
      ~s(<circle cx="#{x_scaled}" cy="#{y_scaled}" r="3" fill="yellow" />)
    end)
    |> Enum.join("\n")
  end

  def hull_to_svg(points, width \\ 500, height \\ 500) do
    {min_x, max_x} = Enum.min_max_by(points, fn {x, _} -> x end)
    {min_y, max_y} = Enum.min_max_by(points, fn {_, y} -> y end)

    {min_x, _} = min_x
    {max_x, _} = max_x
    {_, min_y} = min_y
    {_, max_y} = max_y

    scale_x = (width - 20) / (max_x - min_x)
    scale_y = (height - 20) / (max_y - min_y)

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
end
