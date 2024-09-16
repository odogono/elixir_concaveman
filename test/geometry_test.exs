defmodule Concaveman.GeometryTest do
  use ExUnit.Case

  #   alias Concaveman.Geometry.{point_in_polygon, orient_2d_fast, convex_hull}
  import Concaveman.Geometry

  describe "point_in_polygon" do
    test "with simple square" do
      polygon = [{0, 0}, {0, 1}, {1, 1}, {1, 0}]
      assert point_in_polygon?({0.5, 0.5}, polygon) == true, "point inside"
      assert point_in_polygon?({1.5, 0.5}, polygon) == false, "point outside"
      assert point_in_polygon?({0, 0}, polygon) == true, "point on vertex"
      assert point_in_polygon?({0.5, 0}, polygon) == true, "point on edge"

      # Additional test cases
      assert point_in_polygon?({0, 0.5}, polygon) == true, "point on left edge"
      assert point_in_polygon?({1, 0.5}, polygon) == false, "point on right edge"
      assert point_in_polygon?({0.5, 1}, polygon) == false, "point on top edge"

      assert point_in_polygon?({-0.1, 0.5}, polygon) == false,
             "point slightly outside left edge"

      assert point_in_polygon?({1.1, 0.5}, polygon) == false,
             "point slightly outside right edge"

      assert point_in_polygon?({0.5, -0.1}, polygon) == false,
             "point slightly below bottom edge"

      assert point_in_polygon?({0.5, 1.1}, polygon) == false,
             "point slightly above top edge"
    end

    test "with complex shape" do
      complex_polygon = [{0, 0}, {2, 0}, {2, 2}, {1, 1}, {0, 2}]

      assert point_in_polygon?({0.5, 0.5}, complex_polygon) == true,
             "point inside complex shape"

      assert point_in_polygon?({1.5, 0.5}, complex_polygon) == true,
             "point inside complex shape"

      assert point_in_polygon?({1, 1.5}, complex_polygon) == false, "point in concave part"

      assert point_in_polygon?({2.1, 1}, complex_polygon) == false,
             "point outside complex shape"
    end

    test "with self-intersecting polygon" do
      self_intersecting = [{0, 0}, {2, 2}, {2, 0}, {0, 2}]
      assert point_in_polygon?({1, 1}, self_intersecting) == true, "point at intersection"
      assert point_in_polygon?({0.5, 0.5}, self_intersecting) == false, "point in one part"
      assert point_in_polygon?({1.5, 1.5}, self_intersecting) == true, "point in other part"
      assert point_in_polygon?({0.5, 1.5}, self_intersecting) == false, "point outside"
    end
  end

  describe "orient_2d_fast" do
    test "returns positive value for counter-clockwise orientation" do
      assert orient_2d_fast({0, 0}, {1, 1}, {0, 1}) < 0, "counterclockwise"
      assert orient_2d_fast({0, 0}, {0, 1}, {1, 1}) > 0, "clockwise"
      assert orient_2d_fast({0, 0}, {0.5, 0.5}, {1, 1}) === 0.0, "collinear"
    end
  end

  describe "convex_hull" do
    test "returns the same points for a triangle" do
      points = [{0, 0}, {1, 0}, {0, 1}]
      result = convex_hull(points)
      #   IO.inspect(result, label: "result")
      assert result == [{0, 0}, {0, 1}, {1, 0}], "convex hull of triangle"
    end

    test "with simple square" do
      points = [{0, 0}, {0, 1}, {1, 1}, {1, 0}]
      #   IO.inspect(convex_hull(points))
      assert convex_hull(points) == [{0, 0}, {0, 1}, {1, 1}, {1, 0}], "convex hull of square"
    end

    test "should exclude interior points" do
      points = [{0, 0}, {0, 4}, {4, 4}, {4, 0}, {2, 2}]
      assert convex_hull(points) == [{0, 0}, {0, 4}, {4, 4}, {4, 0}], "convex hull of square"
    end

    test "should handle collinear points" do
      points = [{0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}]
      assert convex_hull(points) == [{0, 0}, {4, 4}]
    end

    test "should return empty array for empty input" do
      assert convex_hull([]) == []
    end

    test "should return empty array for single input" do
      assert convex_hull([{0, 0}]) == []
    end

    test "should handle a more complex shape" do
      points = [
        {0, 0},
        {1, 1},
        {2, 2},
        {3, 1},
        {4, 0},
        {3, -1},
        {2, -2},
        {1, -1},
        {1.5, 0}
      ]

      assert convex_hull(points) == [{0, 0}, {2, 2}, {4, 0}, {2, -2}]
    end
  end
end
