# PEnum

Parallel `Enum`. This library provides a set of functions similar to the
ones in the [Enum](https://hexdocs.pm/elixir/Enum.html) module except that
the function is executed on each element parallel.

The behavior of each of the functions should be the same as the `Enum` varieties,
except that order of execution is not guaranteed.

Except where otherwise noted, the function names are identical to the ones in
`Enum` but with a `p` in front. For example, `PEnum.pmap` is a parallel version of
`Enum.map`.

## Installation

It is [available in Hex](https://hex.pm/docs/publish) and package can be installed
by adding `p_enum` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:p_enum, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/p_enum](https://hexdocs.pm/p_enum).

### Examples

```elixir
expensive_function = fn n -> Enum.reduce(1..n, &Kernel.*/2) end

[30000, 40000, 50000] |> PEnum.pmap(expensive_function)
```

```elixir
def numbers_less_than_five(enumerable) do
  enumerable
  |> PEnum.pfilter(fn n ->
    time = DateTime.utc_now()
    :timer.sleep(n * 1000)
    DateTime.diff(DateTime.utc_now(), time) < 5
  end)
end
```

### Functions

* `pchunk_by/2`
* `pcount/2`
* `pdedup_by/2`
* `peach/2`
* `pfilter/2`
* `pgroup_by/2`
* `pgroup_by/3`
* `group_byp/2`
* `group_byp/3`
* `pgroup_byp/2`
* `pgroup_byp/3`
* `pflat_map/2`
* `pinto/3`
* `pmap/2`
* `pmap_every/3`
* `pmap_join/2`
* `pmap_join/3`
* `pmax_by/2`
* `pmax_by/3`
* `pmin_by/2`
* `pmin_by/3`
* `pmin_max_by/2`
* `pmin_max_by/3`
* `preject/2`
* `puniq_by/2`

#### Group by family

The `Enum.group_by` function takes two functions as arguments:
a `key_fun` and a `value_fun`. Since someone may want to run either
or both in parallel, there are three `PEnum` functions:

* `pgroup_by` - runs only `key_fun` in parallel
* `group_byp` - runs only `value_fun` in parallel
* `pgroup_byp` - runs both `key_fun` and `value_fun` in parallel
