defmodule Mechanize.Form.SubmitButton do
  @moduledoc false

  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.{Form, Queryable}
  alias Mechanize.Form.ParameterizableField
  alias Mechanize.Query.BadCriteriaError

  use Mechanize.Form.FieldMatcher
  use Mechanize.Form.FieldUpdater

  @derive [ParameterizableField, Queryable, Elementable]
  defstruct element: nil, name: nil, value: nil, label: nil

  @type t :: %__MODULE__{
          element: Element.t(),
          name: String.t(),
          value: String.t(),
          label: String.t()
        }

  def new(%Element{name: "button"} = el) do
    %Mechanize.Form.SubmitButton{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      label: Element.text(el)
    }
  end

  def new(%Element{name: "input"} = el) do
    %Mechanize.Form.SubmitButton{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value),
      label: Element.attr(el, :value)
    }
  end

  def click(_form, nil) do
    raise ArgumentError, message: "Can't click on button because button is nil."
  end

  def click(form, criteria) when is_list(criteria) do
    form
    |> Form.submit_buttons_with(criteria)
    |> maybe_click_on_button(form)
  end

  def click(form, label) when is_binary(label) do
    form
    |> Form.submit_buttons_with(fn button -> button.label == label end)
    |> maybe_click_on_button(form)
  end

  def click(form, %__MODULE__{} = button) do
    Form.submit(form, button)
  end

  def click(form, label) do
    form
    |> Form.submit_buttons_with(fn button -> button.label != nil and button.label =~ label end)
    |> maybe_click_on_button(form)
  end

  defp maybe_click_on_button(buttons, form) do
    case buttons do
      [] ->
        raise BadCriteriaError, message: "Can't click on submit button because no button was found for given criteria"

      [button] ->
        click(form, button)

      buttons ->
        raise BadCriteriaError,
          message:
            "Can't decide which submit button to click because #{length(buttons)} buttons were found for given criteria"
    end
  end
end