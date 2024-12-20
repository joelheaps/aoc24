# Run as: iex --dot-iex path/to/notebook.exs

# Title: Day 13

Mix.install([
  {:kino, "~> 0.14.2"},
  {:kino_aoc, "~> 0.1.7"},
  {:tucan, "~> 0.4.1"},
  {:kino_vega_lite, "~> 0.1.13"}
])

# ── Part 1 ──

example = """
p=0,4 v=3,-3
p=6,3 v=-1,-3
p=10,3 v=-1,2
p=2,0 v=2,-1
p=0,0 v=1,3
p=3,0 v=-2,-2
p=7,6 v=-1,-3
p=3,0 v=-1,-2
p=9,3 v=2,3
p=7,3 v=-1,2
p=2,4 v=2,-3
p=9,5 v=-3,-3
"""

{{:ok, input}, grid_dims} = if true do
    {
      KinoAOC.download_puzzle("2024", "14", System.fetch_env!("LB_AOC_SESSION")),
      {101, 103}
    }
else
  {{:ok, example}, {11, 7}}
end

parse_num_pair = fn pair -> pair
  |> String.split(",")
  |> Enum.map(
    fn piece ->
      String.replace(piece, ~r/[^\d|^-]/, "") |> String.to_integer()
    end)
  |> List.to_tuple()
end

parse_robot = fn string ->
  parts = String.split(string, "v")
  loc = Enum.at(parts, 0) |> parse_num_pair.()
  vel = Enum.at(parts, 1) |> parse_num_pair.()
  {loc, vel}
end

robots = input |> String.trim() |> String.split("\n")
  |> Enum.map(&parse_robot.(&1))

defmodule Part1 do
  def get_final_pos({{xi, yi}, {xv, yv}}, {xsize, ysize}, iter) do
    {
      rem(rem((xsize + xv) * iter, xsize) + xi, xsize),
      rem(rem((ysize + yv) * iter, ysize) + yi, ysize),
    }
  end

  def get_all_final_pos(robots, grid_dims, iter) do
    Enum.map(
      robots,
      fn robot -> get_final_pos(robot, grid_dims, iter) end
    )
  end

  def get_quadrant_counts(finals, mx, my) do
    Enum.reduce(
      finals, %{}, fn {x, y}, acc ->
        cond do
          x < mx and y < my -> Map.update(acc, :a, 1, & &1 + 1)
          x < mx and y > my -> Map.update(acc, :b, 1, & &1 + 1)
          x > mx and y < my -> Map.update(acc, :c, 1, & &1 + 1)
          x > mx and y > my -> Map.update(acc, :d, 1, & &1 + 1)
          true -> acc
        end
      end
    )
  end
end

finals = Part1.get_all_final_pos(robots, grid_dims, 100)

{xsize, ysize} = grid_dims
{mx, my} = Enum.map(
  [xsize, ysize],
  & :math.floor(&1 / 2) |> trunc()
)
  |> List.to_tuple()

quadrant_counts = Part1.get_quadrant_counts(finals, mx, my)

result = quadrant_counts |> Map.values() |> Enum.product()

# ── Part 2 ──

iters = 0..100
gen_plot = fn iter ->
  finals = Part1.get_all_final_pos(robots, grid_dims, iter)
  {xs, ys} = Enum.reduce(finals, {[], []}, fn {x, y}, {xs, ys} -> {[x | xs], [y | ys]} end)
  
  VegaLite.new(width: 640, height: 640)
    |> VegaLite.data_from_values(x: xs, y: ys)
    |> Tucan.scatter("x", "y")
    |> Tucan.set_title("#{iter}")
end

Stream.iterate(0, & &1 + 1)
    |> Task.async_stream(
      fn iter ->
        IO.puts("Writing image #{iter}...")
        plotfile = gen_plot.(iter) |> Tucan.Export.save!("#{iter}.png")
      end,
      max_concurrency: 10
    )
    |> Enum.each(fn _ -> IO.puts("Done?") end)
