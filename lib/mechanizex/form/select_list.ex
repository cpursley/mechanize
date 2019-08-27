defmodule Mechanizex.Form.SelectList do
  alias Mechanizex.Page.{Element, Elementable}
  alias Mechanizex.Form.Option
  alias Mechanizex.Query
  alias Mechanizex.{Form, Query, Queryable}

  @derive [Queryable, Elementable]
  @enforce_keys [:element]
  defstruct element: nil, label: nil, name: nil, options: []

  @type t :: %__MODULE__{
          element: Element.t(),
          label: String.t(),
          name: String.t(),
          options: list()
        }

  def new(%Element{} = el) do
    %__MODULE__{
      element: el,
      name: Element.attr(el, :name),
      label: Element.attr(el, :label),
      options: fetch_options(el)
    }
  end

  defmodule SelectError do
    defexception [:message]
  end

  def options(%__MODULE__{} = select), do: options([select])
  def options(selects), do: Enum.flat_map(selects, & &1.options)

  def selected_options(selects) do
    selects
    |> options()
    |> Enum.filter(fn opt -> opt.selected end)
  end

  defp fetch_options(el) do
    el
    |> Query.search("option")
    |> Enum.with_index()
    |> Enum.map(&Option.new(&1))
  end

  def update_options(select, fun) do
    %__MODULE__{select | options: Enum.map(select.options, fun)}
  end

  defmacro __using__(_opts) do
    quote do
      alias unquote(__MODULE__)
      use Mechanizex.Form.FieldMatcher, for: unquote(__MODULE__)
      use Mechanizex.Form.FieldUpdater, for: unquote(__MODULE__)
    end
  end

  def select(form, criteria) do
    {opts_criteria, criteria} = Keyword.pop(criteria, :options, [])
    assert_select_found(form, criteria)

    Form.update_select_lists_with(form, criteria, fn select ->
      assert_options_found(select.options, opts_criteria)

      update_options(select, fn opt ->
        cond do
          Query.match?(opt, opts_criteria) ->
            %Option{opt | selected: true}

          Element.attr_present?(select, :multiple) ->
            opt

          true ->
            %Option{opt | selected: false}
        end
      end)
    end)
    |> assert_single_option_selected
  end

  defp assert_select_found(form, criteria) do
    if Form.select_lists_with(form, criteria) == [],
      do: raise(SelectError, "No select found with criteria #{inspect(criteria)}")
  end

  defp assert_options_found(options, criteria) do
    if Enum.filter(options, &Query.match?(&1, criteria)) == [],
      do: raise(SelectError, "No option found with criteria #{inspect(criteria)} in select")
  end

  defp assert_single_option_selected(form) do
    form
    |> Form.select_lists_with(multiple: false)
    |> Stream.map(fn select -> {select.name, length(selected_options(select))} end)
    |> Stream.filter(fn {_, selected} -> selected > 1 end)
    |> Enum.map(fn {name, _} -> name end)
    |> case do
      [] ->
        form

      names ->
        raise SelectError, "Multiple selected options on single select list with name(s) #{names}"
    end
  end
end