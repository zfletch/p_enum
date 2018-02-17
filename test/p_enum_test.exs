defmodule PEnumTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  require Logger

  doctest PEnum

  describe "pchunk_by/2" do
    test "behavior matches Enum" do
      assert PEnum.pchunk_by([1, 2, 2, 3, 4, 4, 6, 7, 7], &(rem(&1, 2) == 1)) ==
               [[1], [2, 2], [3], [4, 4, 6], [7, 7]]

      assert PEnum.pchunk_by([1, 2, 3, 4], fn _ -> true end) == [[1, 2, 3, 4]]
      assert PEnum.pchunk_by([], fn _ -> true end) == []
      assert PEnum.pchunk_by([1], fn _ -> true end) == [[1]]

      assert PEnum.pchunk_by(1..4, fn _ -> true end) == [[1, 2, 3, 4]]
      assert PEnum.pchunk_by(1..4, &(rem(&1, 2) == 1)) == [[1], [2], [3], [4]]
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pchunk_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.chunk_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pcount/2" do
    test "behavior matches Enum" do
      assert PEnum.pcount([1, 2, 3], fn x -> rem(x, 2) == 0 end) == 1
      assert PEnum.pcount([], fn x -> rem(x, 2) == 0 end) == 0
      assert PEnum.pcount([1, true, false, nil], & &1) == 2

      assert PEnum.pcount(1..5, fn x -> rem(x, 2) == 0 end) == 2
      assert PEnum.pcount(1..1, fn x -> rem(x, 2) == 0 end) == 0
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pcount([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.count([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pdedup_by/2" do
    test "behavior matches Enum" do
      assert PEnum.pdedup_by([{1, :x}, {2, :y}, {2, :z}, {1, :x}], fn {x, _} -> x end) ==
               [{1, :x}, {2, :y}, {1, :x}]

      assert PEnum.pdedup_by([5, 1, 2, 3, 2, 1], fn x -> x > 2 end) == [5, 1, 3, 2]

      assert PEnum.pdedup_by(1..3, fn _ -> 1 end) == [1]
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pdedup_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.dedup_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "peach/2" do
    test "behavior matches Enum" do
      assert PEnum.peach([], fn x -> x end) == :ok

      fun = fn -> PEnum.peach([1, 2, 3], fn n -> Logger.error("peach #{n}") end) end
      assert capture_log(fun) =~ "peach 1"
      assert capture_log(fun) =~ "peach 2"
      assert capture_log(fun) =~ "peach 3"

      assert PEnum.peach(1..0, fn x -> x end) == :ok
      fun = fn -> PEnum.peach(1..3, fn n -> Logger.error("peach #{n}") end) end
      assert capture_log(fun) =~ "peach 1"
      assert capture_log(fun) =~ "peach 2"
      assert capture_log(fun) =~ "peach 3"
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.peach([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.each([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pflat_map/2" do
    test "behavior matches Enum" do
      assert PEnum.pflat_map([], fn x -> [x, x] end) == []
      assert PEnum.pflat_map([1, 2, 3], fn x -> [x, x] end) == [1, 1, 2, 2, 3, 3]
      assert PEnum.pflat_map([1, 2, 3], fn x -> x..(x + 1) end) == [1, 2, 2, 3, 3, 4]

      assert PEnum.pflat_map(1..3, fn x -> [x, x] end) == [1, 1, 2, 2, 3, 3]
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pflat_map([1, 2, 3], fn _ -> [:timer.sleep(100)] end)
      end)

      refute_time_within(200, fn ->
        Enum.flat_map([1, 2, 3], fn _ -> [:timer.sleep(100)] end)
      end)
    end
  end

  describe "pfilter/2" do
    test "behavior matches Enum" do
      assert PEnum.pfilter([1, 2, 3], fn x -> rem(x, 2) == 0 end) == [2]
      assert PEnum.pfilter([2, 4, 6], fn x -> rem(x, 2) == 0 end) == [2, 4, 6]

      assert PEnum.pfilter([1, 2, false, 3, nil], & &1) == [1, 2, 3]
      assert PEnum.pfilter([1, 2, 3], &match?(1, &1)) == [1]
      assert PEnum.pfilter([1, 2, 3], &match?(x when x < 3, &1)) == [1, 2]
      assert PEnum.pfilter([1, 2, 3], fn _ -> true end) == [1, 2, 3]

      assert PEnum.pfilter(1..3, fn x -> rem(x, 2) == 0 end) == [2]
      assert PEnum.pfilter(1..6, fn x -> rem(x, 2) == 0 end) == [2, 4, 6]

      assert PEnum.pfilter(1..3, &match?(1, &1)) == [1]
      assert PEnum.pfilter(1..3, &match?(x when x < 3, &1)) == [1, 2]
      assert PEnum.pfilter(1..3, fn _ -> true end) == [1, 2, 3]
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pfilter([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.filter([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pgroup_by/3" do
    test "behavior matches Enum" do
      assert PEnum.pgroup_by([], fn _ -> raise "oops" end) == %{}
      assert PEnum.pgroup_by([1, 2, 3], &rem(&1, 2)) == %{0 => [2], 1 => [1, 3]}

      assert PEnum.pgroup_by(1..6, &rem(&1, 3)) == %{0 => [3, 6], 1 => [1, 4], 2 => [2, 5]}

      assert PEnum.pgroup_by(1..6, &rem(&1, 3), &(&1 * 2)) ==
               %{0 => [6, 12], 1 => [2, 8], 2 => [4, 10]}
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pgroup_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.group_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        PEnum.pgroup_by([1, 2, 3], & &1, fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "group_byp/3" do
    test "behavior matches Enum" do
      assert PEnum.group_byp([], fn _ -> raise "oops" end) == %{}
      assert PEnum.group_byp([1, 2, 3], &rem(&1, 2)) == %{0 => [2], 1 => [1, 3]}

      assert PEnum.group_byp(1..6, &rem(&1, 3)) == %{0 => [3, 6], 1 => [1, 4], 2 => [2, 5]}

      assert PEnum.group_byp(1..6, &rem(&1, 3), &(&1 * 2)) ==
               %{0 => [6, 12], 1 => [2, 8], 2 => [4, 10]}
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.group_byp([1, 2, 3], & &1, fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.group_by([1, 2, 3], & &1, fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pgroup_byp/3" do
    test "behavior matches Enum" do
      assert PEnum.pgroup_byp([], fn _ -> raise "oops" end) == %{}
      assert PEnum.pgroup_byp([1, 2, 3], &rem(&1, 2)) == %{0 => [2], 1 => [1, 3]}

      assert PEnum.pgroup_byp(1..6, &rem(&1, 3)) == %{0 => [3, 6], 1 => [1, 4], 2 => [2, 5]}

      assert PEnum.pgroup_byp(1..6, &rem(&1, 3), &(&1 * 2)) ==
               %{0 => [6, 12], 1 => [2, 8], 2 => [4, 10]}
    end

    test "runs in parallel" do
      assert_time_within(250, fn ->
        PEnum.pgroup_byp([1, 2, 3], fn _ -> :timer.sleep(100) end, fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.group_by([1, 2, 3], fn _ -> :timer.sleep(100) end, fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pinto/3" do
    test "behavior matches Enum" do
      assert PEnum.pinto([1, 2, 3], [], fn x -> x * 2 end) == [2, 4, 6]
      assert PEnum.pinto([1, 2, 3], "numbers: ", &to_string/1) == "numbers: 123"

      assert_raise ArgumentError, fn ->
        PEnum.pinto([2, 3], %{a: 1}, & &1)
      end

      assert PEnum.pinto(1..5, [], fn x -> x * 2 end) == [2, 4, 6, 8, 10]
      assert PEnum.pinto(1..3, "numbers: ", &to_string/1) == "numbers: 123"
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pinto([1, 2, 3], [], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.into([1, 2, 3], [], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pmap/2" do
    test "behavior matches Enum" do
      assert PEnum.pmap([], fn x -> x * 2 end) == []
      assert PEnum.pmap([1, 2, 3], fn x -> x * 2 end) == [2, 4, 6]

      assert PEnum.pmap(1..3, fn x -> x * 2 end) == [2, 4, 6]
      assert PEnum.pmap(-1..-3, fn x -> x * 2 end) == [-2, -4, -6]
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pmap([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.map([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pmap_every/3" do
    test "behavior matches Enum" do
      assert PEnum.pmap_every([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 2, fn x -> x * 2 end) ==
               [2, 2, 6, 4, 10, 6, 14, 8, 18, 10]

      assert PEnum.pmap_every([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 3, fn x -> x * 2 end) ==
               [2, 2, 3, 8, 5, 6, 14, 8, 9, 20]

      assert PEnum.pmap_every([], 2, fn x -> x * 2 end) == []
      assert PEnum.pmap_every([1, 2], 2, fn x -> x * 2 end) == [2, 2]

      assert PEnum.pmap_every([1, 2, 3], 0, fn _x -> raise :i_should_have_never_been_invoked end) ==
               [1, 2, 3]

      assert PEnum.pmap_every(1..3, 1, fn x -> x * 2 end) == [2, 4, 6]

      assert_raise FunctionClauseError, fn ->
        PEnum.pmap_every([1, 2, 3], -1, fn x -> x * 2 end)
      end

      assert_raise FunctionClauseError, fn ->
        PEnum.pmap_every(1..10, 3.33, fn x -> x * 2 end)
      end

      assert PEnum.pmap_every([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 9, fn x -> x + 1000 end) ==
               [1001, 2, 3, 4, 5, 6, 7, 8, 9, 1010]

      assert PEnum.pmap_every([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 10, fn x -> x + 1000 end) ==
               [1001, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      assert PEnum.pmap_every([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 100, fn x -> x + 1000 end) ==
               [1001, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      assert PEnum.pmap_every(1..10, 2, fn x -> x * 2 end) == [2, 2, 6, 4, 10, 6, 14, 8, 18, 10]

      assert PEnum.pmap_every(-1..-10, 2, fn x -> x * 2 end) ==
               [-2, -2, -6, -4, -10, -6, -14, -8, -18, -10]

      assert PEnum.pmap_every(1..2, 2, fn x -> x * 2 end) == [2, 2]
      assert PEnum.pmap_every(1..3, 0, fn x -> x * 2 end) == [1, 2, 3]

      assert_raise FunctionClauseError, fn ->
        PEnum.pmap_every(1..3, -1, fn x -> x * 2 end)
      end
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pmap_every([1, 2, 3], 1, fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.map_every([1, 2, 3], 1, fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pmap_join/3" do
    test "behavior matches Enum" do
      assert PEnum.pmap_join([], " = ", &(&1 * 2)) == ""
      assert PEnum.pmap_join([1, 2, 3], " = ", &(&1 * 2)) == "2 = 4 = 6"
      assert PEnum.pmap_join([1, 2, 3], &(&1 * 2)) == "246"
      assert PEnum.pmap_join(["", "", 1, 2, "", 3, "", "\n"], ";", & &1) == ";;1;2;;3;;\n"
      assert PEnum.pmap_join([""], "", & &1) == ""
      assert PEnum.pmap_join(fn acc, _ -> acc end, ".", &(&1 + 0)) == ""

      assert PEnum.pmap_join(1..0, " = ", &(&1 * 2)) == "2 = 0"
      assert PEnum.pmap_join(1..3, " = ", &(&1 * 2)) == "2 = 4 = 6"
      assert PEnum.pmap_join(1..3, &(&1 * 2)) == "246"
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pmap_join([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.map_join([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pmax_by/2" do
    test "behavior matches Enum" do
      assert PEnum.pmax_by(["a", "aa", "aaa"], fn x -> String.length(x) end) == "aaa"

      assert_raise Enum.EmptyError, fn ->
        PEnum.pmax_by([], fn x -> String.length(x) end)
      end

      assert_raise Enum.EmptyError, fn ->
        PEnum.pmax_by(%{}, & &1)
      end

      assert PEnum.pmax_by(1..1, fn x -> :math.pow(-2, x) end) == 1
      assert PEnum.pmax_by(1..3, fn x -> :math.pow(-2, x) end) == 2
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pmax_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.max_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pmax_by/3" do
    test "behavior matches Enum" do
      assert PEnum.pmax_by(["a", "aa", "aaa"], fn x -> String.length(x) end, fn -> nil end) ==
               "aaa"

      assert PEnum.pmax_by([], fn x -> String.length(x) end, fn -> :empty_value end) ==
               :empty_value

      assert PEnum.pmax_by(%{}, & &1, fn -> :empty_value end) == :empty_value
      assert PEnum.pmax_by(%{}, & &1, fn -> {:a, :tuple} end) == {:a, :tuple}
      assert_runs_enumeration_only_once(&PEnum.pmax_by(&1, fn e -> e end, fn -> nil end))
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pmax_by([1, 2, 3], fn _ -> :timer.sleep(100) end, fn -> 1 end)
      end)

      refute_time_within(200, fn ->
        Enum.max_by([1, 2, 3], fn _ -> :timer.sleep(100) end, fn -> 1 end)
      end)
    end
  end

  describe "pmin_by/2" do
    test "behavior matches Enum" do
      assert PEnum.pmin_by(["a", "aa", "aaa"], fn x -> String.length(x) end) == "a"

      assert_raise Enum.EmptyError, fn ->
        PEnum.pmin_by([], fn x -> String.length(x) end)
      end

      assert_raise Enum.EmptyError, fn ->
        PEnum.pmin_by(%{}, & &1)
      end

      assert PEnum.pmin_by(1..1, fn x -> :math.pow(-2, x) end) == 1
      assert PEnum.pmin_by(1..3, fn x -> :math.pow(-2, x) end) == 3
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pmin_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.min_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pmin_by/3" do
    test "behavior matches Enum" do
      assert PEnum.pmin_by(["a", "aa", "aaa"], fn x -> String.length(x) end, fn -> nil end) == "a"

      assert PEnum.pmin_by([], fn x -> String.length(x) end, fn -> :empty_value end) ==
               :empty_value

      assert PEnum.pmin_by(%{}, & &1, fn -> :empty_value end) == :empty_value
      assert PEnum.pmin_by(%{}, & &1, fn -> {:a, :tuple} end) == {:a, :tuple}
      assert_runs_enumeration_only_once(&PEnum.pmin_by(&1, fn e -> e end, fn -> nil end))
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pmin_by([1, 2, 3], fn _ -> :timer.sleep(100) end, fn -> 1 end)
      end)

      refute_time_within(200, fn ->
        Enum.min_by([1, 2, 3], fn _ -> :timer.sleep(100) end, fn -> 1 end)
      end)
    end
  end

  describe "pmin_max_by/2" do
    test "behavior matches Enum" do
      assert PEnum.pmin_max_by(["aaa", "a", "aa"], fn x -> String.length(x) end) == {"a", "aaa"}

      assert_raise Enum.EmptyError, fn ->
        PEnum.pmin_max_by([], fn x -> String.length(x) end)
      end

      assert PEnum.pmin_max_by(1..1, fn x -> x end) == {1, 1}
      assert PEnum.pmin_max_by(1..3, fn x -> x end) == {1, 3}
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pmin_max_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.min_max_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "pmin_max_by/3" do
    test "behavior matches Enum" do
      assert PEnum.pmin_max_by(["aaa", "a", "aa"], fn x -> String.length(x) end, fn -> nil end) ==
               {"a", "aaa"}

      assert PEnum.pmin_max_by([], fn x -> String.length(x) end, fn -> {:no_min, :no_max} end) ==
               {:no_min, :no_max}

      assert PEnum.pmin_max_by(%{}, fn x -> String.length(x) end, fn -> {:no_min, :no_max} end) ==
               {:no_min, :no_max}

      assert_runs_enumeration_only_once(&PEnum.pmin_max_by(&1, fn x -> x end, fn -> nil end))
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.pmin_max_by([1, 2, 3], fn _ -> :timer.sleep(100) end, fn -> 1 end)
      end)

      refute_time_within(200, fn ->
        Enum.min_max_by([1, 2, 3], fn _ -> :timer.sleep(100) end, fn -> 1 end)
      end)
    end
  end

  describe "preject/2" do
    test "behavior matches Enum" do
      assert PEnum.preject([1, 2, 3], fn x -> rem(x, 2) == 0 end) == [1, 3]
      assert PEnum.preject([2, 4, 6], fn x -> rem(x, 2) == 0 end) == []
      assert PEnum.preject([1, true, nil, false, 2], & &1) == [nil, false]

      assert PEnum.preject(1..3, fn x -> rem(x, 2) == 0 end) == [1, 3]
      assert PEnum.preject(1..6, fn x -> rem(x, 2) == 0 end) == [1, 3, 5]
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.preject([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.reject([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
  end

  describe "puniq_by/2" do
    test "behavior matches Enum" do
      assert PEnum.puniq_by([1, 2, 3, 2, 1], fn x -> x end) == [1, 2, 3]

      assert PEnum.puniq_by(1..3, fn x -> x end) == [1, 2, 3]
    end

    test "runs in parallel" do
      assert_time_within(200, fn ->
        PEnum.puniq_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)

      refute_time_within(200, fn ->
        Enum.uniq_by([1, 2, 3], fn _ -> :timer.sleep(100) end)
      end)
    end
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

  defp assert_time_within(ms, fun) do
    time = DateTime.utc_now()
    fun.()
    assert DateTime.diff(DateTime.utc_now(), time, :millisecond) < ms
  end

  defp refute_time_within(ms, fun) do
    time = DateTime.utc_now()
    fun.()
    refute DateTime.diff(DateTime.utc_now(), time, :millisecond) < ms
  end
end
