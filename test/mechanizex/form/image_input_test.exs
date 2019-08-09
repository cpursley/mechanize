defmodule Mechanizex.Form.ImageInputTest do
  use ExUnit.Case, async: true
  alias Mechanizex.{Page, Form}
  alias Mechanizex.Page.Element
  alias Mechanizex.Form.{ImageInput, ClickError}
  import TestHelper

  setup do
    {:ok, %{page: page} = vars} = stub_requests("/test/htdocs/image_input_test.html")
    {:ok, Map.put(vars, :form, Page.form_with(page))}
  end

  describe ".image_inputs" do
    test "retreve all image buttons", %{form: form} do
      inputs = Form.image_inputs(form)

      assert Enum.map(inputs, &{&1.name, &1.x, &1.y}) == [
               {"map1", 0, 0},
               {"map2", 0, 0}
             ]
    end

    test "elements loaded", %{form: form} do
      inputs = Form.image_inputs(form)

      refute Enum.empty?(inputs)
      Enum.each(inputs, fn image -> assert %Element{} = image.element end)
    end
  end

  describe ".image_inputs_with" do
    test "retrieve by criteria with name", %{form: form} do
      inputs = Form.image_inputs_with(form, name: "map2")

      assert length(inputs) == 1
      assert List.first(inputs).name == "map2"
    end
  end

  describe ".click" do
    test "send (0,0) click coords as default", %{form: form, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert Plug.Conn.fetch_query_params(conn).params == %{
                 "username" => "gustavo",
                 "passwd" => "123456",
                 "map2.x" => "0",
                 "map2.y" => "0"
               }

        Plug.Conn.resp(conn, 200, "NEXT PAGE")
      end)

      ImageInput.click(form, name: "map2")
    end

    test "passing click coords as named params", %{form: form, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert Plug.Conn.fetch_query_params(conn).params == %{
                 "username" => "gustavo",
                 "passwd" => "123456",
                 "map2.x" => "10",
                 "map2.y" => "10"
               }

        Plug.Conn.resp(conn, 200, "NEXT PAGE")
      end)

      ImageInput.click(form, name: "map2", x: 10, y: 10)
    end

    test "returns next page", %{form: form, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "NEXT PAGE")
      end)

      assert form
             |> ImageInput.click(name: "map2", x: 10, y: 10)
             |> Page.body() == "NEXT PAGE"
    end

    test "raise exception when image not found", %{form: form} do
      assert_raise ClickError, ~r/not found/, fn ->
        ImageInput.click(form, name: "lero", x: 10, y: 10)
      end
    end

    test "raise exception when many images found", %{form: form} do
      assert_raise ClickError, ~r/2 images were found/, fn ->
        ImageInput.click(form, name: ~r/map/, x: 10, y: 10)
      end
    end
  end
end
