defmodule Mechanize.HTMLParser do
  @moduledoc false

  alias Mechanize.Page
  alias Mechanize.Page.Element

  @type selector :: String.t()
  @type attribute :: atom()

  @callback search(Page.t() | list(Element.t()) | [], selector) :: list(Element.t())
  @callback filter(Page.t() | list(Element.t()) | [], selector) :: list(Element.t())
  @callback raw_html(Page.t() | Element.t()) :: String.t()
end
