defmodule PLEnum do
  @moduledoc """
  Documentation for PLEnum.
  """

  @type element :: any

  @spec pchunk_by(Enumerable.t, (element -> any)) :: [list]
  def pchunk_by(enumerable, fun) do
    enumerable
    |> by_func(fun, &Enum.chunk_by/2)
  end

  @spec pcount(Enumerable.t, (element -> as_boolean(term))) :: non_neg_integer
  def pcount(enumerable, fun) do
    enumerable
    |> acc_func(fun, &Enum.count/2)
  end

  @spec pdedup_by(Enumerable.t, (element -> term)) :: list
  def pdedup_by(enumerable, fun) do
    enumerable
    |> by_func(fun, &Enum.dedup_by/2)
  end

  @spec peach(Enumerable.t, (element -> any)) :: :ok
  def peach(enumerable, fun) do
    enumerable
    |> Enum.map(fn (n) -> (Task.async(fn -> fun.(n) end)) end)
    |> Enum.each(&Task.await/1)

    :ok
  end

  @spec pflat_map(Enumerable.t, (element -> Enumerable.t)) :: list
  def pflat_map(enumerable, fun) do
    enumerable
    |> acc_func(fun, &Enum.flat_map/2)
  end

  @spec pfilter(Enumerable.t, (element -> as_boolean(term))) :: list
  def pfilter(enumerable, fun) do
    enumerable
    |> by_func(fun, &Enum.filter/2)
  end

  @spec pgroup_by(Enumerable.t, (element -> any), (element -> any)) :: map
  def pgroup_by(enumerable, key_fun, value_fun \\ fn x -> x end)
  def pgroup_by(enumerable, key_fun, value_fun) do
    enumerable
    |> pmap(fn (n) -> {key_fun.(n), n} end)
    |> Enum.group_by(fn ({f, _}) -> f end, fn ({_, v}) -> value_fun.(v) end)
  end

  @spec group_byp(Enumerable.t, (element -> any), (element -> any)) :: map
  def group_byp(enumerable, key_fun, value_fun \\ fn x -> x end)
  def group_byp(enumerable, key_fun, value_fun) do
    enumerable
    |> Enum.group_by(key_fun)
    |> pmap(value_fun)
  end

  @spec pgroup_byp(Enumerable.t, (element -> any), (element -> any)) :: map
  def pgroup_byp(enumerable, key_fun, value_fun \\ fn x -> x end)
  def pgroup_byp(enumerable, key_fun, value_fun) do
    enumerable
    |> pmap(fn (n) -> {key_fun.(n), value_fun.(n)} end)
    |> Enum.map(fn ({_, v}) -> v end)
  end

  @spec into(Enumerable.t(), Collectable.t(), (term -> term)) :: Collectable.t()
  def into(enumerable, collectable, transform) do
    enumerable
    |> pmap(transform)
    |> Enum.into(collectable)
  end

  @spec pmap(Enumerable.t, (element -> any)) :: list
  def pmap(enumerable, fun) do
    enumerable
    |> Enum.map(fn (n) -> (Task.async(fn -> fun.(n) end)) end)
    |> Enum.map(&Task.await/1)
  end

  @spec pmap_every(Enumerable.t, non_neg_integer, (element -> any)) :: list
  def pmap_every(enumerable, nth, fun) do
    enumerable
    |> Enum.map_every(nth, fn (n) -> (Task.async(fn -> fun.(n) end)) end)
    |> Enum.map(&Task.await/1)
  end

  @spec pmap_join(Enumerable.t, String.t(), (element -> String.Chars.t())) :: String.t()
  def pmap_join(enumerable, joiner \\ "", mapper) do
    enumerable
    |> pmap(mapper)
    |> Enum.join(joiner)
  end

  @spec pmax_by(Enumerable.t, (element -> any), (() -> empty_result)) :: element | empty_result | no_return
        when empty_result: any
  def pmax_by(enumerable, fun, empty_fallback \\ fn -> raise Enum.EmptyError end) do
    enumerable
    |> pmap(fun)
    |> Enum.max(empty_fallback)
  end

  @spec pmin_by(Enumerable.t, (element -> any), (() -> empty_result)) :: element | empty_result | no_return
        when empty_result: any
  def pmin_by(enumerable, fun, empty_fallback \\ fn -> raise Enum.EmptyError end) do
    enumerable
    |> pmap(fun)
    |> Enum.min(empty_fallback)
  end

  @spec pmin_max_by(Enumerable.t, (element -> any), (() -> empty_result)) ::
          {element, element} | empty_result | no_return
        when empty_result: any
  def pmin_max_by(enumerable, fun, empty_fallback \\ fn -> raise Enum.EmptyError end) do
    enumerable
    |> pmap(fun)
    |> Enum.min_max(empty_fallback)
  end

  @spec preject(Enumerable.t, (element -> as_boolean(term))) :: list
  def preject(enumerable, fun) do
    enumerable
    |> acc_func(fun, &Enum.reject/2)
  end

  @spec puniq_by(Enumerable.t, (element -> term)) :: list
  def puniq_by(enumerable, fun) do
    enumerable
    |> by_func(fun, &Enum.uniq_by/2)
  end

  defp by_func(enumerable, fun, wrap_fun) do
    enumerable
    |> pmap(fn (n) -> {fun.(n), n} end)
    |> wrap_fun.(fn ({f, _}) -> f end)
    |> Enum.map(fn ({_, v}) -> v end)
  end

  defp acc_func(enumerable, fun, acc_fun) do
    enumerable
    |> pmap(fun)
    |> acc_fun.(& &1)
  end
end
