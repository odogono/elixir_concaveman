defmodule Concaveman.Geometry do
  @type point :: {number(), number()}

  @spec point_in_polygon?(point(), list(point()), integer(), integer()) :: boolean()
  def point_in_polygon?(point, vs, start \\ 0, end_index \\ nil) do
    {x, y} = point
    end_index = end_index || length(vs)
    len = end_index - start

    Enum.reduce_while(0..(len - 1), {false, len - 1}, fn i, {inside, j} ->
      {xi, yi} = Enum.at(vs, i + start)
      {xj, yj} = Enum.at(vs, j + start)

      intersect =
        yi > y != yj > y and
          x < (xj - xi) * (y - yi) / (yj - yi) + xi

      new_inside = if intersect, do: !inside, else: inside

      if i == len - 1 do
        {:halt, new_inside}
      else
        {:cont, {new_inside, i}}
      end
    end)
  end

  def fast_convex_hull(points) do
    {left, top, right, bottom} = find_extreme_points(points)

    cull = [left, top, right, bottom]

    filtered =
      cull ++
        Enum.filter(points, fn point ->
          not point_in_polygon?(point, cull)
        end)

    convex_hull(filtered)
  end

  @epsilon 1.1102230246251565e-16
  @errbound3 (3.0 + 16.0 * @epsilon) * @epsilon

  def orientation3(a, b, c) do
    l = (Enum.at(a, 1) - Enum.at(c, 1)) * (Enum.at(b, 0) - Enum.at(c, 0))
    r = (Enum.at(a, 0) - Enum.at(c, 0)) * (Enum.at(b, 1) - Enum.at(c, 1))
    det = l - r

    {s, early_return} =
      cond do
        l > 0 ->
          if r <= 0 do
            {nil, det}
          else
            {l + r, nil}
          end

        l < 0 ->
          if r >= 0 do
            {nil, det}
          else
            {-(l + r), nil}
          end

        true ->
          {nil, det}
      end

    case early_return do
      nil ->
        tol = @errbound3 * s

        if det >= tol or det <= -tol do
          det
        else
          orientation3_exact(a, b, c)
        end

      value ->
        value
    end
  end

  defp orientation3_exact(m0, m1, m2) do
    p =
      sum(
        sum(prod(Enum.at(m1, 1), Enum.at(m2, 0)), prod(-Enum.at(m2, 1), Enum.at(m1, 0))),
        sum(prod(Enum.at(m0, 1), Enum.at(m1, 0)), prod(-Enum.at(m1, 1), Enum.at(m0, 0)))
      )

    n = sum(prod(Enum.at(m0, 1), Enum.at(m2, 0)), prod(-Enum.at(m2, 1), Enum.at(m0, 0)))
    d = sub(p, n)
    List.last(d)
  end

  # Helper functions (these would need to be implemented)
  defp sum(a, b), do: :not_implemented
  defp prod(a, b), do: :not_implemented
  defp sub(a, b), do: :not_implemented

  @spec orient_2d_fast(point(), point(), point()) :: number()
  def orient_2d_fast({ax, ay}, {bx, by}, {cx, cy}) do
    (ay - cy) * (bx - cx) - (ax - cx) * (by - cy)
  end

  @spec convex_hull([point]) :: [point]
  def convex_hull(points) do
    sorted_points = Enum.sort(points, &compare_by_x/2)

    lower = compute_hull(sorted_points)
    upper = compute_hull(Enum.reverse(sorted_points))

    Enum.drop(lower, -1) ++ Enum.drop(upper, -1)
  end

  defp compute_hull(points) do
    Enum.reduce(points, [], fn point, hull ->
      hull = remove_non_convex_points(hull, point)
      [point | hull]
    end)
    |> Enum.reverse()
  end

  defp remove_non_convex_points(upper, point) do
    case upper do
      [p2, p1 | rest] ->
        if orient_2d_fast(p1, p2, point) <= 0 do
          remove_non_convex_points([p1 | rest], point)
        else
          upper
        end

      _ ->
        upper
    end
  end

  @spec compare_by_x(point, point) :: boolean
  defp compare_by_x({ax, ay}, {bx, by}) do
    cond do
      ax == bx -> ay <= by
      true -> ax < bx
    end
  end

  defp find_extreme_points(points) do
    Enum.reduce(points, {hd(points), hd(points), hd(points), hd(points)}, fn point,
                                                                             {left, top, right,
                                                                              bottom} ->
      {
        min_by_x(point, left),
        min_by_y(point, top),
        max_by_x(point, right),
        max_by_y(point, bottom)
      }
    end)
  end

  defp min_by_x(p1, p2), do: if(elem(p1, 0) < elem(p2, 0), do: p1, else: p2)
  defp min_by_y(p1, p2), do: if(elem(p1, 1) < elem(p2, 1), do: p1, else: p2)
  defp max_by_x(p1, p2), do: if(elem(p1, 0) > elem(p2, 0), do: p1, else: p2)
  defp max_by_y(p1, p2), do: if(elem(p1, 1) > elem(p2, 1), do: p1, else: p2)

  def intersects_fast(p1, q1, p2, q2) do
    p1 != q2 and q1 != p2 and orient_2d_fast(p1, q1, p2) > 0 != orient_2d_fast(p1, q1, q2) > 0 and
      orient_2d_fast(p2, q2, p1) > 0 != orient_2d_fast(p2, q2, q1) > 0
  end

  def get_sq_dist(p1, p2) do
    dx = elem(p1, 0) - elem(p2, 0)
    dy = elem(p1, 1) - elem(p2, 1)
    dx * dx + dy * dy
  end

  def sq_seg_dist(p, p1, p2) do
    x = elem(p1, 0)
    y = elem(p1, 1)
    dx = elem(p2, 0) - x
    dy = elem(p2, 1) - y
    px = elem(p, 0)
    py = elem(p, 1)

    t = ((px - x) * dx + (py - y) * dy) / (dx * dx + dy * dy)

    if t < 0 do
      get_sq_dist(p, p1)
    else
      if t > 1 do
        get_sq_dist(p, p2)
      else
        get_sq_dist([x + t * dx, y + t * dy], p)
      end
    end
  end

  # def point_in_polygon_alt(point, polygon) do
  #   polygon
  #   |> Enum.chunk_every(2)
  #   |> Enum.with_index()
  #   |> Enum.reduce(false, fn {p1, p2}, acc ->
  #     acc or intersects(point, p1, p2, p1)
  #   end)
  # end
end
