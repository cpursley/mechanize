defmodule Mechanizex.Form.TextInput do
  alias Mechanizex.Page.{Element, Elementable}
  alias Mechanizex.Form.ParameterizableField
  alias Mechanizex.Queryable

  @derive [ParameterizableField, Queryable, Elementable]
  @enforce_keys [:element]
  defstruct element: nil, label: nil, name: nil, value: nil

  @type t :: %__MODULE__{
          element: Element.t(),
          label: String.t(),
          name: String.t(),
          value: String.t()
        }

  def new(%Element{name: "input"} = el) do
    %Mechanizex.Form.TextInput{
      element: el,
      name: Element.attr(el, :name),
      value: Element.attr(el, :value)
    }
  end

  def new(%Element{name: "textarea"} = el) do
    %Mechanizex.Form.TextInput{
      element: el,
      name: Element.attr(el, :name),
      value: Element.text(el)
    }
  end
end
