defmodule Mechanizex.FormTest do
  use ExUnit.Case, async: true
  alias Mechanizex
  alias Mechanizex.Test.Support.LocalPageLoader
  alias Mechanizex.Page.Element
  alias Mechanizex.{Form, Request, Response, Page}
  alias Mechanizex.Form.{TextInput, SubmitButton}
  import Mox

  setup_all do
    {:ok, agent: Mechanizex.new(http_adapter: :mock)}
  end

  describe ".fill_field" do
    test "update a first field by name", %{agent: agent} do
      assert(
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
        |> Page.form_with()
        |> Form.fill_field("username", with: "gustavo")
        |> Form.fill_field("passwd", with: "123456")
        |> Form.fields()
        |> Enum.map(&{&1.name, &1.value}) == [
          {"username", "gustavo"},
          {"passwd", "123456"}
        ]
      )
    end

    test "creates a new field", %{agent: agent} do
      fields =
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
        |> Page.form_with()
        |> Mechanizex.fill_field("captcha", with: "checked")
        |> Form.fields()
        |> Enum.map(&{&1.name, &1.value})

      assert fields == [
               {"captcha", "checked"},
               {"username", nil},
               {"passwd", "12345"}
             ]
    end
  end

  describe ".update_field" do
    test "updates all fields with same name" do
      assert(
        %Form{
          element: :fake,
          fields: [
            %TextInput{element: :fake, name: "article[categories][]", value: "1"},
            %TextInput{element: :fake, name: "article[categories][]", value: "2"}
          ]
        }
        |> Form.update_field("article[categories][]", "3")
        |> Form.fields()
        |> Enum.map(&{&1.name, &1.value}) == [
          {"article[categories][]", "3"},
          {"article[categories][]", "3"}
        ]
      )
    end
  end

  describe ".add_field" do
    test "adds a field even if already exists" do
      assert(
        %Form{element: :fake}
        |> Form.add_field("user[codes][]", "1")
        |> Form.add_field("user[codes][]", "2")
        |> Form.add_field("user[codes][]", "3")
        |> Form.fields()
        |> Enum.map(&{&1.name, &1.value}) == [
          {"user[codes][]", "3"},
          {"user[codes][]", "2"},
          {"user[codes][]", "1"}
        ]
      )
    end
  end

  describe ".delete_field" do
    test "removes all fields with the given name" do
      assert(
        %Form{
          element: :fake,
          fields: [
            %TextInput{element: :fake, name: "article[categories][]", value: "1"},
            %TextInput{element: :fake, name: "article[categories][]", value: "2"},
            %TextInput{element: :fake, name: "username", value: "gustavo"}
          ]
        }
        |> Form.delete_field("article[categories][]")
        |> Form.fields()
        |> Enum.map(&{&1.name, &1.value}) == [{"username", "gustavo"}]
      )
    end
  end

  describe ".parse_fields" do
    test "parse all generic text input", %{agent: agent} do
      fields =
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_all_generic_text_inputs.html")
        |> Page.form_with()
        |> Form.fields()
        |> Enum.map(fn %TextInput{name: name, value: value} -> {name, value} end)

      assert fields == [
               {"color1", "color1 value"},
               {"date1", "date1 value"},
               {"datetime1", "datetime1 value"},
               {"email1", "email1 value"},
               {"hidden1", "hidden1 value"},
               {"month1", "month1 value"},
               {"number1", "number1 value"},
               {"password1", "password1 value"},
               {"range1", "range1 value"},
               {"search1", "search1 value"},
               {"tel1", "tel1 value"},
               {"text1", "text1 value"},
               {"time1", "time1 value"},
               {"url1", "url1 value"},
               {"week1", "week1 value"},
               {"textarea1", "textarea1 value"}
             ]
    end

    test "parse disabled fields", %{agent: agent} do
      fields =
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_disabled_generic_inputs.html")
        |> Page.form_with()
        |> Form.fields()
        |> Enum.map(fn f -> {f.name, Element.attr_present?(f, :disabled)} end)

      assert fields == [
               {"color1", false},
               {"date1", true},
               {"datetime1", true},
               {"email1", true},
               {"textarea1", true}
             ]
    end

    test "parse elements without name", %{agent: agent} do
      fields =
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_inputs_without_name.html")
        |> Page.form_with()
        |> Form.fields()
        |> Enum.map(fn %TextInput{name: name, value: value} -> {name, value} end)

      assert fields == [
               {nil, "gustavo"},
               {nil, "123456"}
             ]
    end

    test "parse all submit buttons", %{agent: agent} do
      assert agent
             |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_all_kinds_of_buttons.html")
             |> Page.form_with()
             |> Form.fields()
             |> Enum.map(fn %{
                              name: name,
                              value: value,
                              text: text,
                              id: id
                            } ->
               {name, value, text, id}
             end) == [
               {"button1", "button1_value", "button1_value", nil},
               {"button2", "button2_value", "button2_value", nil},
               {nil, "button3_value", "button3_value", nil},
               {"button4", "button4_value", nil, nil},
               {"button5", "button5_value", "Button 5", nil},
               {nil, "button6_value", "Button 6", nil},
               {"button7", "button7_value", "Button 7", nil},
               {"button8", "button8_value", "Button 8", nil},
               {nil, nil, "Button 9", "button9"},
               {"button10", "button10_value", "Button 10", nil},
               {"button14", "button14_value", "Button 14", nil},
               {"button15", "button15_value", "Button 15", nil},
               {"button16", "button16_value", "Button 16", nil},
               {"button17", "button17_value", "Button 17", nil},
               {"button18", "button18_value", "Button 18", nil},
               {"button19", "button19_value", "Button 19", nil},
               {"BUTTON20", "button20_value", "Button 20", nil}
             ]
    end
  end

  describe ".submit_buttons" do
    test "return a list of submit buttons from fields" do
      assert(
        %Form{
          element: :fake,
          fields: [
            %TextInput{element: :fake, name: "username", value: "gustavo"},
            %SubmitButton{element: :fake, name: "submit1"},
            %SubmitButton{element: :fake, name: "submit2"}
          ]
        }
        |> Form.submit_buttons() == [
          %SubmitButton{element: :fake, name: "submit1"},
          %SubmitButton{element: :fake, name: "submit2"}
        ]
      )
    end

    test "return a empty list if no submit button found" do
      assert(
        %Form{
          element: :fake,
          fields: [
            %TextInput{element: :fake, name: "username", value: "gustavo"}
          ]
        }
        |> Form.submit_buttons() == []
      )
    end
  end

  describe ".submit" do
    setup :verify_on_exit!

    test "method is get when method attribute missing", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :get, url: "https://htdocs.local/login"} = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_method_attribute_missing.html")
      |> Page.form_with()
      |> Mechanizex.submit()
    end

    test "method is get when method attribute is blank", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :get, url: "https://htdocs.local/login"} = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_method_attribute_blank.html")
      |> Page.form_with()
      |> Mechanizex.submit()
    end

    test "method post", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :post, url: "https://htdocs.local/login"} = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_method_attribute_post.html")
      |> Page.form_with()
      |> Mechanizex.submit()
    end

    test "absent action attribute", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :post,
                               url: "https://htdocs.local/test/htdocs/form_with_absent_action.html"
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absent_action.html")
      |> Page.form_with()
      |> Mechanizex.submit()
    end

    test "empty action url", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :post,
                               url: "https://htdocs.local/test/htdocs/form_with_blank_action.html"
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_blank_action.html")
      |> Page.form_with()
      |> Mechanizex.submit()
    end

    test "relative action url", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :post, url: "https://htdocs.local/test/login"} = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_relative_action.html")
      |> Page.form_with()
      |> Mechanizex.submit()
    end

    test "absolute action url", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _, %Request{method: :post, url: "https://www.foo.com/login"} = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
      |> Page.form_with()
      |> Mechanizex.submit()
    end

    test "input fields submission", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :post,
                               url: "https://www.foo.com/login",
                               params: [{"username", "gustavo"}, {"passwd", "gu123456"}]
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_absolute_action.html")
      |> Page.form_with()
      |> Mechanizex.fill_field("username", with: "gustavo")
      |> Mechanizex.fill_field("passwd", with: "gu123456")
      |> Mechanizex.submit()
    end

    test "doest not submit disabled fields", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :post,
                               url: "https://htdocs.local/test/htdocs/form_with_disabled_generic_inputs.html",
                               params: [{"color1", "color1 value"}]
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_with_disabled_generic_inputs.html")
      |> Page.form_with()
      |> Mechanizex.submit()
    end
  end

  describe ".click_button" do
    test "click by text", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :post,
                               url: "https://htdocs.local/test/htdocs/form_button_click_test.html",
                               params: [
                                 {"button1_name", "button1_value"},
                                 {"username", nil},
                                 {"passwd", nil}
                               ]
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_button_click_test.html")
      |> Page.form_with()
      |> Form.click_button("Button 1")
    end

    test "click by name", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :post,
                               url: "https://htdocs.local/test/htdocs/form_button_click_test.html",
                               params: [
                                 {"button1_name", "button1_value"},
                                 {"username", nil},
                                 {"passwd", nil}
                               ]
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_button_click_test.html")
      |> Page.form_with()
      |> Form.click_button("button1_name")
    end

    test "click by id", %{agent: agent} do
      Mechanizex.HTTPAdapter.Mock
      |> expect(:request, fn _,
                             %Request{
                               method: :post,
                               url: "https://htdocs.local/test/htdocs/form_button_click_test.html",
                               params: [
                                 {"button1_name", "button1_value"},
                                 {"username", nil},
                                 {"passwd", nil}
                               ]
                             } = req ->
        {:ok, %Page{agent: agent, request: req, response: %Response{}}}
      end)

      agent
      |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_button_click_test.html")
      |> Page.form_with()
      |> Form.click_button("button1_id")
    end

    test "click on unexistent button raises an exception", %{agent: agent} do
      assert_raise Mechanizex.Form.ButtonNotFound, fn ->
        agent
        |> LocalPageLoader.get("https://htdocs.local/test/htdocs/form_button_click_test.html")
        |> Page.form_with()
        |> Form.click_button("Unexistent button")
      end
    end

    setup :verify_on_exit!
  end
end
