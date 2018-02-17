defmodule PLEnumTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  require Logger

  doctest PLEnum

  test "pchunk_by/2" do
    assert PLEnum.pchunk_by([1, 2, 2, 3, 4, 4, 6, 7, 7], &(rem(&1, 2) == 1)) ==
             [[1], [2, 2], [3], [4, 4, 6], [7, 7]]

    assert PLEnum.pchunk_by([1, 2, 3, 4], fn _ -> true end) == [[1, 2, 3, 4]]
    assert PLEnum.pchunk_by([], fn _ -> true end) == []
    assert PLEnum.pchunk_by([1], fn _ -> true end) == [[1]]

    assert PLEnum.pchunk_by(1..4, fn _ -> true end) == [[1, 2, 3, 4]]
    assert PLEnum.pchunk_by(1..4, &(rem(&1, 2) == 1)) == [[1], [2], [3], [4]]
  end

  test "pcount/2" do
    assert PLEnum.pcount([1, 2, 3], fn x -> rem(x, 2) == 0 end) == 1
    assert PLEnum.pcount([], fn x -> rem(x, 2) == 0 end) == 0
    assert PLEnum.pcount([1, true, false, nil], & &1) == 2

    assert PLEnum.pcount(1..5, fn x -> rem(x, 2) == 0 end) == 2
    assert PLEnum.pcount(1..1, fn x -> rem(x, 2) == 0 end) == 0
  end

  test "pdedup_by/2" do
    assert PLEnum.pdedup_by([{1, :x}, {2, :y}, {2, :z}, {1, :x}], fn {x, _} -> x end) ==
             [{1, :x}, {2, :y}, {1, :x}]

    assert PLEnum.pdedup_by([5, 1, 2, 3, 2, 1], fn x -> x > 2 end) == [5, 1, 3, 2]

    assert PLEnum.pdedup_by(1..3, fn _ -> 1 end) == [1]
  end

  test "peach/2" do
    assert PLEnum.peach([], fn x -> x end) == :ok

    fun = fn -> PLEnum.peach([1, 2, 3], fn (n) -> Logger.error("peach #{n}") end) end
    assert capture_log(fun) =~ "peach 1"
    assert capture_log(fun) =~ "peach 2"
    assert capture_log(fun) =~ "peach 3"

    assert PLEnum.peach(1..0, fn x -> x end) == :ok
    fun = fn -> PLEnum.peach(1..3, fn (n) -> Logger.error("peach #{n}") end) end
    assert capture_log(fun) =~ "peach 1"
    assert capture_log(fun) =~ "peach 2"
    assert capture_log(fun) =~ "peach 3"
  end

  test "pflat_map/2" do
    assert PLEnum.pflat_map([], fn x -> [x, x] end) == []
    assert PLEnum.pflat_map([1, 2, 3], fn x -> [x, x] end) == [1, 1, 2, 2, 3, 3]
    assert PLEnum.pflat_map([1, 2, 3], fn x -> x..(x + 1) end) == [1, 2, 2, 3, 3, 4]

    assert PLEnum.pflat_map(1..3, fn x -> [x, x] end) == [1, 1, 2, 2, 3, 3]
  end

  test "pfilter/2" do
    assert PLEnum.pfilter([1, 2, 3], fn x -> rem(x, 2) == 0 end) == [2]
    assert PLEnum.pfilter([2, 4, 6], fn x -> rem(x, 2) == 0 end) == [2, 4, 6]

    assert PLEnum.pfilter([1, 2, false, 3, nil], & &1) == [1, 2, 3]
    assert PLEnum.pfilter([1, 2, 3], &match?(1, &1)) == [1]
    assert PLEnum.pfilter([1, 2, 3], &match?(x when x < 3, &1)) == [1, 2]
    assert PLEnum.pfilter([1, 2, 3], fn _ -> true end) == [1, 2, 3]

    assert PLEnum.pfilter(1..3, fn x -> rem(x, 2) == 0 end) == [2]
    assert PLEnum.pfilter(1..6, fn x -> rem(x, 2) == 0 end) == [2, 4, 6]

    assert PLEnum.pfilter(1..3, &match?(1, &1)) == [1]
    assert PLEnum.pfilter(1..3, &match?(x when x < 3, &1)) == [1, 2]
    assert PLEnum.pfilter(1..3, fn _ -> true end) == [1, 2, 3]
  end

  test "pgroup_by/3" do
    assert PLEnum.pgroup_by([], fn _ -> raise "oops" end) == %{}
    assert PLEnum.pgroup_by([1, 2, 3], &rem(&1, 2)) == %{0 => [2], 1 => [1, 3]}

    assert PLEnum.pgroup_by(1..6, &rem(&1, 3)) == %{0 => [3, 6], 1 => [1, 4], 2 => [2, 5]}

    assert PLEnum.pgroup_by(1..6, &rem(&1, 3), &(&1 * 2)) ==
             %{0 => [6, 12], 1 => [2, 8], 2 => [4, 10]}
  end

  test "group_byp/3" do
    assert PLEnum.group_byp([], fn _ -> raise "oops" end) == %{}
    assert PLEnum.group_byp([1, 2, 3], &rem(&1, 2)) == %{0 => [2], 1 => [1, 3]}

    assert PLEnum.group_byp(1..6, &rem(&1, 3)) == %{0 => [3, 6], 1 => [1, 4], 2 => [2, 5]}

    assert PLEnum.group_byp(1..6, &rem(&1, 3), &(&1 * 2)) ==
             %{0 => [6, 12], 1 => [2, 8], 2 => [4, 10]}
  end

  test "pgroup_byp/3" do
    assert PLEnum.pgroup_byp([], fn _ -> raise "oops" end) == %{}
    assert PLEnum.pgroup_byp([1, 2, 3], &rem(&1, 2)) == %{0 => [2], 1 => [1, 3]}

    assert PLEnum.pgroup_byp(1..6, &rem(&1, 3)) == %{0 => [3, 6], 1 => [1, 4], 2 => [2, 5]}

    assert PLEnum.pgroup_byp(1..6, &rem(&1, 3), &(&1 * 2)) ==
             %{0 => [6, 12], 1 => [2, 8], 2 => [4, 10]}
  end

  test "pinto/3" do
    assert PLEnum.pinto([1, 2, 3], [], fn x -> x * 2 end) == [2, 4, 6]
    assert PLEnum.pinto([1, 2, 3], "numbers: ", &to_string/1) == "numbers: 123"

    assert_raise ArgumentError, fn ->
      PLEnum.pinto([2, 3], %{a: 1}, & &1)
    end

    assert PLEnum.pinto(1..5, [], fn x -> x * 2 end) == [2, 4, 6, 8, 10]
    assert PLEnum.pinto(1..3, "numbers: ", &to_string/1) == "numbers: 123"
  end

  test "pmap/2" do
    assert PLEnum.pmap([], fn x -> x * 2 end) == []
    assert PLEnum.pmap([1, 2, 3], fn x -> x * 2 end) == [2, 4, 6]

    assert PLEnum.pmap(1..3, fn x -> x * 2 end) == [2, 4, 6]
    assert PLEnum.pmap(-1..-3, fn x -> x * 2 end) == [-2, -4, -6]
  end

  test "pmap_every/3" do
    assert PLEnum.pmap_every([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 2, fn x -> x * 2 end) ==
             [2, 2, 6, 4, 10, 6, 14, 8, 18, 10]

    assert PLEnum.pmap_every([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 3, fn x -> x * 2 end) ==
             [2, 2, 3, 8, 5, 6, 14, 8, 9, 20]

    assert PLEnum.pmap_every([], 2, fn x -> x * 2 end) == []
    assert PLEnum.pmap_every([1, 2], 2, fn x -> x * 2 end) == [2, 2]

    assert PLEnum.pmap_every([1, 2, 3], 0, fn _x -> raise :i_should_have_never_been_invoked end) ==
             [1, 2, 3]

    assert PLEnum.pmap_every(1..3, 1, fn x -> x * 2 end) == [2, 4, 6]

    assert_raise FunctionClauseError, fn ->
      PLEnum.pmap_every([1, 2, 3], -1, fn x -> x * 2 end)
    end

    assert_raise FunctionClauseError, fn ->
      PLEnum.pmap_every(1..10, 3.33, fn x -> x * 2 end)
    end

    assert PLEnum.pmap_every([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 9, fn x -> x + 1000 end) ==
             [1001, 2, 3, 4, 5, 6, 7, 8, 9, 1010]

    assert PLEnum.pmap_every([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 10, fn x -> x + 1000 end) ==
             [1001, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    assert PLEnum.pmap_every([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 100, fn x -> x + 1000 end) ==
             [1001, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    assert PLEnum.pmap_every(1..10, 2, fn x -> x * 2 end) == [2, 2, 6, 4, 10, 6, 14, 8, 18, 10]

    assert PLEnum.pmap_every(-1..-10, 2, fn x -> x * 2 end) ==
             [-2, -2, -6, -4, -10, -6, -14, -8, -18, -10]

    assert PLEnum.pmap_every(1..2, 2, fn x -> x * 2 end) == [2, 2]
    assert PLEnum.pmap_every(1..3, 0, fn x -> x * 2 end) == [1, 2, 3]

    assert_raise FunctionClauseError, fn ->
      PLEnum.pmap_every(1..3, -1, fn x -> x * 2 end)
    end
  end

  test "pmap_join/3" do
    assert PLEnum.pmap_join([], " = ", &(&1 * 2)) == ""
    assert PLEnum.pmap_join([1, 2, 3], " = ", &(&1 * 2)) == "2 = 4 = 6"
    assert PLEnum.pmap_join([1, 2, 3], &(&1 * 2)) == "246"
    assert PLEnum.pmap_join(["", "", 1, 2, "", 3, "", "\n"], ";", & &1) == ";;1;2;;3;;\n"
    assert PLEnum.pmap_join([""], "", & &1) == ""
    assert PLEnum.pmap_join(fn acc, _ -> acc end, ".", &(&1 + 0)) == ""

    assert PLEnum.pmap_join(1..0, " = ", &(&1 * 2)) == "2 = 0"
    assert PLEnum.pmap_join(1..3, " = ", &(&1 * 2)) == "2 = 4 = 6"
    assert PLEnum.pmap_join(1..3, &(&1 * 2)) == "246"
  end

  test "pmax_by/2" do
    assert PLEnum.pmax_by(["a", "aa", "aaa"], fn x -> String.length(x) end) == "aaa"

    assert_raise Enum.EmptyError, fn ->
      PLEnum.pmax_by([], fn x -> String.length(x) end)
    end

    assert_raise Enum.EmptyError, fn ->
      PLEnum.pmax_by(%{}, & &1)
    end

    assert PLEnum.pmax_by(1..1, fn x -> :math.pow(-2, x) end) == 1
    assert PLEnum.pmax_by(1..3, fn x -> :math.pow(-2, x) end) == 2
  end

  test "pmax_by/3" do
    assert PLEnum.pmax_by(["a", "aa", "aaa"], fn x -> String.length(x) end, fn -> nil end) == "aaa"
    assert PLEnum.pmax_by([], fn x -> String.length(x) end, fn -> :empty_value end) == :empty_value
    assert PLEnum.pmax_by(%{}, & &1, fn -> :empty_value end) == :empty_value
    assert PLEnum.pmax_by(%{}, & &1, fn -> {:a, :tuple} end) == {:a, :tuple}
    assert_runs_enumeration_only_once(&PLEnum.pmax_by(&1, fn e -> e end, fn -> nil end))
  end

  test "pmin_by/2" do
    assert PLEnum.pmin_by(["a", "aa", "aaa"], fn x -> String.length(x) end) == "a"

    assert_raise Enum.EmptyError, fn ->
      PLEnum.pmin_by([], fn x -> String.length(x) end)
    end

    assert_raise Enum.EmptyError, fn ->
      PLEnum.pmin_by(%{}, & &1)
    end

    assert PLEnum.pmin_by(1..1, fn x -> :math.pow(-2, x) end) == 1
    assert PLEnum.pmin_by(1..3, fn x -> :math.pow(-2, x) end) == 3
  end

  test "pmin_by/3" do
    assert PLEnum.pmin_by(["a", "aa", "aaa"], fn x -> String.length(x) end, fn -> nil end) == "a"
    assert PLEnum.pmin_by([], fn x -> String.length(x) end, fn -> :empty_value end) == :empty_value
    assert PLEnum.pmin_by(%{}, & &1, fn -> :empty_value end) == :empty_value
    assert PLEnum.pmin_by(%{}, & &1, fn -> {:a, :tuple} end) == {:a, :tuple}
    assert_runs_enumeration_only_once(&PLEnum.pmin_by(&1, fn e -> e end, fn -> nil end))
  end

  test "pmin_max_by/2" do
    assert PLEnum.pmin_max_by(["aaa", "a", "aa"], fn x -> String.length(x) end) == {"a", "aaa"}

    assert_raise Enum.EmptyError, fn ->
      PLEnum.pmin_max_by([], fn x -> String.length(x) end)
    end

    assert PLEnum.pmin_max_by(1..1, fn x -> x end) == {1, 1}
    assert PLEnum.pmin_max_by(1..3, fn x -> x end) == {1, 3}
  end

  test "pmin_max_by/3" do
    assert PLEnum.pmin_max_by(["aaa", "a", "aa"], fn x -> String.length(x) end, fn -> nil end) ==
             {"a", "aaa"}

    assert PLEnum.pmin_max_by([], fn x -> String.length(x) end, fn -> {:no_min, :no_max} end) ==
             {:no_min, :no_max}

    assert PLEnum.pmin_max_by(%{}, fn x -> String.length(x) end, fn -> {:no_min, :no_max} end) ==
             {:no_min, :no_max}

    assert_runs_enumeration_only_once(&PLEnum.pmin_max_by(&1, fn x -> x end, fn -> nil end))
  end

  test "preject/2" do
    assert PLEnum.preject([1, 2, 3], fn x -> rem(x, 2) == 0 end) == [1, 3]
    assert PLEnum.preject([2, 4, 6], fn x -> rem(x, 2) == 0 end) == []
    assert PLEnum.preject([1, true, nil, false, 2], & &1) == [nil, false]

    assert PLEnum.preject(1..3, fn x -> rem(x, 2) == 0 end) == [1, 3]
    assert PLEnum.preject(1..6, fn x -> rem(x, 2) == 0 end) == [1, 3, 5]
  end

  test "puniq_by/2" do
    assert PLEnum.puniq_by([1, 2, 3, 2, 1], fn x -> x end) == [1, 2, 3]

    assert PLEnum.puniq_by(1..3, fn x -> x end) == [1, 2, 3]
  end

  defp assert_runs_enumeration_only_once(enum_fun) do
    enumerator =
      Stream.map([:element], fn element ->
        send(self(), element)
        element
      end)

    enum_fun.(enumerator)
    assert_received :element
    refute_received :element
  end
end
