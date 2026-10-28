defmodule PhoenixProfiler.PhoenixProfilerTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Plug.Conn, only: [put_req_header: 3]

  alias PhoenixProfiler.Elements.{MemoryUsage, Request, RequestDuration}
  alias PhoenixProfiler.Server

  @endpoint PhoenixProfilerTest.Endpoint

  setup do
    {:ok, conn: build_conn()}
  end

  test "profiles a browser request", %{conn: conn} do
    conn = get(conn, "/")

    assert token = conn.private.phoenix_profiler
    assert html_response(conn, 200) =~ ~s[class="phxprof-toolbar" data-token="#{token}"]

    entries = Server.get_entries(token)

    assert {Request,
            %{
              conn: %Plug.Conn{
                method: "GET",
                request_path: "/",
                status: 200,
                private: %{
                  phoenix_action: :index,
                  phoenix_controller: PhoenixProfilerTest.PageController,
                  phoenix_router: PhoenixProfilerTest.Router
                }
              }
            }} = List.keyfind(entries, Request, 0)

    assert {RequestDuration, %{endpoint: duration}} = List.keyfind(entries, RequestDuration, 0)
    assert duration > 0

    assert {MemoryUsage, %{memory: memory}} = List.keyfind(entries, MemoryUsage, 0)
    assert memory > 0
  end

  test "profiles a request handled by a forwarded plug", %{conn: conn} do
    conn = get(conn, "/plug-router")

    assert token = conn.private.phoenix_profiler
    assert html_response(conn, 200) =~ ~s[data-token="#{token}"]

    assert {Request, %{conn: %Plug.Conn{status: 200}}} =
             List.keyfind(Server.get_entries(token), Request, 0)
  end

  test "profiles an api request without injecting the toolbar", %{conn: conn} do
    conn = get(conn, "/api")

    assert response(conn, 200) == ~s({"hello":"world"})
    assert response_content_type(conn, :json)
    assert token = conn.private.phoenix_profiler

    assert {Request,
            %{conn: %Plug.Conn{private: %{phoenix_controller: PhoenixProfilerTest.APIController}}}} =
             List.keyfind(Server.get_entries(token), Request, 0)
  end

  test "stores the entries under the token sent in the request header", %{conn: conn} do
    conn =
      conn
      |> put_req_header("x-phxprof-token", "page-token")
      |> get("/api")

    assert conn.private.phoenix_profiler == "page-token"

    assert {Request, %{conn: %Plug.Conn{request_path: "/api"}}} =
             List.keyfind(Server.get_entries("page-token"), Request, 0)
  end
end
