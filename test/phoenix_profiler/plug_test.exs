defmodule PhoenixProfiler.PlugTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  @toolbar_start "<!-- START Phoenix Web Debug Toolbar -->"
  @toolbar_end "<!-- END Phoenix Web Debug Toolbar -->"

  defp build_conn(path, endpoint \\ PhoenixProfilerTest.Endpoint) do
    :get
    |> conn(path)
    |> put_private(:phoenix_endpoint, endpoint)
  end

  defp html_response(conn, body) do
    conn
    |> put_resp_content_type("text/html")
    |> PhoenixProfiler.call(PhoenixProfiler.init([]))
    |> send_resp(200, body)
  end

  test "injects the toolbar before the </body> tag of html responses" do
    conn = html_response(build_conn("/"), "<html><body><h1>PhoenixProfiler</h1></body></html>")
    body = to_string(conn.resp_body)

    assert token = conn.private.phoenix_profiler
    assert body =~ ~s[<h1>PhoenixProfiler</h1>#{@toolbar_start}]
    assert body =~ ~s[class="phxprof-toolbar" data-token="#{token}"]
    assert String.ends_with?(body, "#{@toolbar_end}\n</body></html>")
  end

  test "injects the toolbar before the last </body> tag" do
    conn =
      html_response(
        build_conn("/"),
        "<html><body><h1><body>PhoenixProfiler</body></h1></body></html>"
      )

    assert to_string(conn.resp_body) =~
             ~s[<h1><body>PhoenixProfiler</body></h1>#{@toolbar_start}]
  end

  test "reuses the token sent in the x-phxprof-token header" do
    conn =
      build_conn("/")
      |> put_req_header("x-phxprof-token", "my-token")
      |> html_response("<html><body></body></html>")

    assert conn.private.phoenix_profiler == "my-token"
    assert to_string(conn.resp_body) =~ ~s[data-token="my-token"]
  end

  test "applies the :toolbar_attrs of the endpoint config" do
    conn =
      html_response(
        build_conn("/", PhoenixProfilerTest.EndpointWithOptions),
        "<html><body></body></html>"
      )

    assert to_string(conn.resp_body) =~
             ~r[<div id="my-toolbar" data-env="test" class="phxprof-toolbar"]
  end

  test "skips the toolbar when the profiler is disabled on the endpoint" do
    conn =
      html_response(
        build_conn("/", PhoenixProfilerTest.EndpointDisabled),
        "<html><body><h1>PhoenixProfiler</h1></body></html>"
      )

    refute conn.private[:phoenix_profiler]
    assert to_string(conn.resp_body) == "<html><body><h1>PhoenixProfiler</h1></body></html>"
  end

  test "skips the toolbar when the endpoint has no :phoenix_profiler config" do
    conn =
      html_response(
        build_conn("/", PhoenixProfilerTest.EndpointNotConfigured),
        "<html><body><h1>PhoenixProfiler</h1></body></html>"
      )

    refute conn.private[:phoenix_profiler]
    assert to_string(conn.resp_body) == "<html><body><h1>PhoenixProfiler</h1></body></html>"
  end

  test "skips the toolbar for paths matching the :except_patterns" do
    conn =
      html_response(
        build_conn("/admin/users", PhoenixProfilerTest.EndpointWithOptions),
        "<html><body></body></html>"
      )

    refute conn.private[:phoenix_profiler]
    assert to_string(conn.resp_body) == "<html><body></body></html>"
  end

  test "skips the toolbar when the html has no body tag" do
    conn = html_response(build_conn("/"), "<h1>PhoenixProfiler</h1>")

    assert conn.private.phoenix_profiler
    assert to_string(conn.resp_body) == "<h1>PhoenixProfiler</h1>"
  end

  test "skips the toolbar for non html responses but keeps the token" do
    conn =
      build_conn("/")
      |> put_resp_content_type("application/json")
      |> PhoenixProfiler.call(PhoenixProfiler.init([]))
      |> send_resp(200, "{}")

    assert conn.private.phoenix_profiler
    assert to_string(conn.resp_body) == "{}"
  end
end
