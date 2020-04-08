defmodule Mechanizex.HTTPAdapter.HTTPoisonTest do
  use ExUnit.Case, async: true
  alias Mechanizex.Request
  import TestHelper

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, adapter: Mechanizex.HTTPAdapter.Httpoison}
  end

  test "simple methods", %{bypass: bypass, adapter: adapter} do
    Bypass.expect(bypass, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/fake_path"
      Plug.Conn.resp(conn, 200, "Lero")
    end)

    res = adapter.request!(%Request{method: :get, url: endpoint_url(bypass, "/fake_path")})

    assert res.code == 200
    assert res.body == "Lero"
  end

  test "simple GET with error", %{bypass: bypass, adapter: adapter} do
    Bypass.down(bypass)

    assert_raise Mechanizex.HTTPAdapter.NetworkError, ~r/connection refused/i, fn ->
      adapter.request!(%Request{method: :get, url: endpoint_url(bypass)})
    end
  end

  test "request headers using GET", %{bypass: bypass, adapter: adapter} do
    Bypass.expect(bypass, fn conn ->
      assert [{_, "text/html"}] = Enum.filter(conn.req_headers, fn {k, _} -> k =~ ~r/content-type/i end)

      assert [{_, "Gustabot"}] = Enum.filter(conn.req_headers, fn {k, _} -> k =~ ~r/user-agent/i end)

      Plug.Conn.resp(conn, 200, "Lero")
    end)

    adapter.request!(%Request{
      method: :get,
      url: endpoint_url(bypass),
      headers: [{"User-Agent", "Gustabot"}, {"content-type", "text/html"}]
    })
  end

  test "handle received headers using GET", %{bypass: bypass, adapter: adapter} do
    Bypass.expect(bypass, fn conn ->
      conn
      |> Plug.Conn.resp(301, "Lero")
      |> Plug.Conn.put_resp_header("Location", "https://www.seomaster.com.br")
    end)

    res = adapter.request!(%Request{method: :get, url: endpoint_url(bypass)})

    assert [{_, "https://www.seomaster.com.br"}] = Enum.filter(res.headers, fn {k, _} -> k =~ ~r/location/i end)
  end
end
