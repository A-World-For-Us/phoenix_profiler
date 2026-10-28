defmodule PhoenixProfiler.ProfilerTest do
  use ExUnit.Case, async: true

  alias Phoenix.LiveView.Socket
  alias PhoenixProfiler.Profiler

  defmodule EnableAliasEndpoint do
    def config(:phoenix_profiler), do: [enable: false]
  end

  defp build_conn(endpoint, path \\ "/") do
    :get
    |> Plug.Test.conn(path)
    |> Plug.Conn.put_private(:phoenix_endpoint, endpoint)
  end

  defp build_socket(endpoint, connected?) do
    socket = %Socket{endpoint: endpoint}
    if connected?, do: %{socket | transport_pid: self()}, else: socket
  end

  describe "enabled?/1 with a Plug.Conn" do
    test "is true when the endpoint has a :phoenix_profiler config" do
      assert Profiler.enabled?(build_conn(PhoenixProfilerTest.Endpoint))
    end

    test "is false when :enabled? is false" do
      refute Profiler.enabled?(build_conn(PhoenixProfilerTest.EndpointDisabled))
    end

    test "is false when the endpoint has no :phoenix_profiler config" do
      refute Profiler.enabled?(build_conn(PhoenixProfilerTest.EndpointNotConfigured))
    end

    test "accepts :enable as an alias of :enabled?" do
      refute Profiler.enabled?(build_conn(EnableAliasEndpoint))
    end

    test "is false when the path matches one of the :except_patterns" do
      endpoint = PhoenixProfilerTest.EndpointWithOptions

      refute Profiler.enabled?(build_conn(endpoint, "/admin"))
      refute Profiler.enabled?(build_conn(endpoint, "/admin/users"))
      refute Profiler.enabled?(build_conn(endpoint, "/internal/oban/jobs"))
      assert Profiler.enabled?(build_conn(endpoint, "/internal"))
      assert Profiler.enabled?(build_conn(endpoint, "/users"))
    end

    test "skips the live reload frame by default" do
      refute Profiler.enabled?(
               build_conn(PhoenixProfilerTest.Endpoint, "/phoenix/live_reload/frame")
             )
    end
  end

  describe "enabled?/1 with a LiveView socket" do
    test "depends on the endpoint config" do
      assert Profiler.enabled?(build_socket(PhoenixProfilerTest.Endpoint, true))
      refute Profiler.enabled?(build_socket(PhoenixProfilerTest.EndpointDisabled, true))
      refute Profiler.enabled?(build_socket(PhoenixProfilerTest.EndpointNotConfigured, true))
    end

    test "ignores the :except_patterns" do
      assert Profiler.enabled?(build_socket(PhoenixProfilerTest.EndpointWithOptions, true))
    end
  end

  describe "enable/2 with a Plug.Conn" do
    test "generates a token and makes the process observable" do
      conn = Profiler.enable(build_conn(PhoenixProfilerTest.Endpoint))

      assert token = conn.private.phoenix_profiler
      assert is_binary(token)
      assert Process.get(:phoenix_profiler_token) == token
    end

    test "uses the given token" do
      conn = Profiler.enable(build_conn(PhoenixProfilerTest.Endpoint), "my-token")

      assert conn.private.phoenix_profiler == "my-token"
      assert Process.get(:phoenix_profiler_token) == "my-token"
    end

    test "keeps the token already set on the conn" do
      conn = Profiler.enable(build_conn(PhoenixProfilerTest.Endpoint), "first")

      assert Profiler.enable(conn, "second") == conn
    end
  end

  describe "enable/2 with a LiveView socket" do
    test "puts the token on a connected socket" do
      socket = Profiler.enable(build_socket(PhoenixProfilerTest.Endpoint, true), "my-token")

      assert socket.private.phoenix_profiler == "my-token"
      assert Process.get(:phoenix_profiler_token) == "my-token"
    end

    test "raises on a disconnected socket" do
      assert_raise RuntimeError, ~r/disconnected socket/, fn ->
        Profiler.enable(build_socket(PhoenixProfilerTest.Endpoint, false))
      end
    end
  end
end
