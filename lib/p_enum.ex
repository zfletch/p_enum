defmodule PEnum do
  @moduledoc """
  Parallel `Enum`. This library provides a set of functions similar to the
  ones in the [Enum](https://hexdocs.pm/elixir/Enum.html) module except that
  the function is executed on each element parallel.

  The behavior of each of the functions should be the same as the `Enum` varieties,
  except that order of execution is not guaranteed.

  Except where otherwise noted, the function names are identical to the ones in
  `Enum` but with a `p` in front. For example, `PEnum.pmap` is a parallel version of
  `Enum.map`.
  """

  @type element :: any

  @spec pchunk_by(Enumerable.t(), (element -> any)) :: [list]
  def pchunk_by(enumerable, fun) do
    enumerable
    |> pmap(fn n -> {fun.(n), n} end)
    |> Enum.chunk_by(fn {f, _} -> f end)
    |> Enum.map(fn chunk ->
      Enum.map(chunk, fn {_, v} -> v end)
    end)
  end

  @spec pcount(Enumerable.t(), (element -> as_boolean(term))) :: non_neg_integer
  def pcount(enumerable, fun) do
    enumerable
    |> acc_func(fun, &Enum.count/2)
  end

  @spec pdedup_by(Enumerable.t(), (element -> term)) :: list
  def pdedup_by(enumerable, fun) do
    enumerable
    |> by_func(fun, &Enum.dedup_by/2)
  end

  @spec peach(Enumerable.t(), (element -> any)) :: :ok
  def peach(enumerable, fun) do
    enumerable
    |> Enum.map(fn n -> Task.async(fn -> fun.(n) end) end)
    |> Enum.each(&Task.await/1)

    :ok
  end

  @spec pflat_map(Enumerable.t(), (element -> Enumerable.t())) :: list
  def pflat_map(enumerable, fun) do
    enumerable
    |> acc_func(fun, &Enum.flat_map/2)
  end

  @spec pfilter(Enumerable.t(), (element -> as_boolean(term))) :: list
  def pfilter(enumerable, fun) do
    enumerable
    |> by_func(fun, &Enum.filter/2)
  end

  @spec pgroup_by(Enumerable.t(), (element -> any), (element -> any)) :: map
  def pgroup_by(enumerable, key_fun, value_fun \\ fn x -> x end)

  def pgroup_by(enumerable, key_fun, value_fun) do
    enumerable
    |> pmap(fn n -> {key_fun.(n), n} end)
    |> Enum.group_by(fn {f, _} -> f end, fn {_, v} -> value_fun.(v) end)
  end

  @spec group_byp(Enumerable.t(), (element -> any), (element -> any)) :: map
  def group_byp(enumerable, key_fun, value_fun \\ fn x -> x end)

  def group_byp(enumerable, key_fun, value_fun) do
    enumerable
    |> Enum.group_by(key_fun)
    |> pinto(%{}, fn {k, group} ->
      {k, pmap(group, value_fun)}
    end)
  end

  @spec pgroup_byp(Enumerable.t(), (element -> any), (element -> any)) :: map
  def pgroup_byp(enumerable, key_fun, value_fun \\ fn x -> x end)

  def pgroup_byp(enumerable, key_fun, value_fun) do
    enumerable
    |> pmap(fn n -> {key_fun.(n), n} end)
    |> pmap(fn {f, v} -> {f, value_fun.(v)} end)
    |> Enum.group_by(fn {f, _} -> f end, fn {_, v} -> v end)
  end

  @spec pinto(Enumerable.t(), Collectable.t(), (term -> term)) :: Collectable.t()
  def pinto(enumerable, collectable, transform) do
    enumerable
    |> pmap(transform)
    |> Enum.into(collectable)
  end

  @spec pmap(Enumerable.t(), (element -> any)) :: list
  def pmap(enumerable, fun) do
    enumerable
    |> Enum.map(fn n -> Task.async(fn -> fun.(n) end) end)
    |> Enum.map(&Task.await/1)
  end

  @spec pmap_every(Enumerable.t(), non_neg_integer, (element -> any)) :: list
  def pmap_every(enumerable, nth, fun) do
    enumerable
    |> Enum.map_every(nth, fn n -> Task.async(fn -> fun.(n) end) end)
    |> Enum.map_every(nth, &Task.await/1)
  end

  @spec pmap_join(Enumerable.t(), String.t(), (element -> String.Chars.t())) :: String.t()
  def pmap_join(enumerable, joiner \\ "", mapper) do
    enumerable
    |> pmap(mapper)
    |> Enum.join(joiner)
  end

  @spec pmax_by(Enumerable.t(), (element -> any), (() -> empty_result)) ::
          element | empty_result | no_return
        when empty_result: any
  def pmax_by(enumerable, fun, empty_fallback \\ fn -> raise Enum.EmptyError end) do
    enumerable
    |> num_by_func(fun, empty_fallback, &Enum.max_by/3)
  end

  @spec pmin_by(Enumerable.t(), (element -> any), (() -> empty_result)) ::
          element | empty_result | no_return
        when empty_result: any
  def pmin_by(enumerable, fun, empty_fallback \\ fn -> raise Enum.EmptyError end) do
    enumerable
    |> num_by_func(fun, empty_fallback, &Enum.min_by/3)
  end

  @spec pmin_max_by(Enumerable.t(), (element -> any), (() -> empty_result)) ::
          {element, element} | empty_result | no_return
        when empty_result: any
  def pmin_max_by(enumerable, fun, empty_fallback \\ fn -> raise Enum.EmptyError end) do
    enumerable
    |> pmap(fn n -> {fun.(n), n} end)
    |> Enum.min_max_by(fn {f, _} -> f end, fn -> :empty end)
    |> case do
      :empty -> empty_fallback.()
      {{_, nv}, {_, xv}} -> {nv, xv}
    end
  end

  @spec preject(Enumerable.t(), (element -> as_boolean(term))) :: list
  def preject(enumerable, fun) do
    enumerable
    |> by_func(fun, &Enum.reject/2)
  end

  @spec puniq_by(Enumerable.t(), (element -> term)) :: list
  def puniq_by(enumerable, fun) do
    enumerable
    |> by_func(fun, &Enum.uniq_by/2)
  end

  defp by_func(enumerable, fun, wrap_fun) do
    enumerable
    |> pmap(fn n -> {fun.(n), n} end)
    |> wrap_fun.(fn {f, _} -> f end)
    |> Enum.map(fn {_, v} -> v end)
  end

  defp acc_func(enumerable, fun, acc_fun) do
    enumerable
    |> pmap(fun)
    |> acc_fun.(& &1)
  end

  defp num_by_func(enumerable, fun, empty_fallback, num_by_fun) do
    enumerable
    |> pmap(fn n -> {fun.(n), n} end)
    |> num_by_fun.(fn {f, _} -> f end, fn -> :empty end)
    |> case do
      :empty -> empty_fallback.()
      {_, v} -> v
    end
  end
end
