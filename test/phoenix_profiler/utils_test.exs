defmodule PhoenixProfiler.UtilsTest do
  # Not async: `elements/0` reads the application env.
  use ExUnit.Case, async: false

  alias PhoenixProfiler.Utils

  defmodule CustomElement do
    use PhoenixProfiler.Element

    def render(assigns), do: ~H""
    def subscribed_events, do: []
    def collect(_event, _measurements, _metadata), do: nil
    def entries_assigns(_entries), do: %{}
  end

  describe "conn_or_socket_config/1" do
    test "returns the endpoint config for a conn" do
      conn =
        :get
        |> Plug.Test.conn("/")
        |> Plug.Conn.put_private(:phoenix_endpoint, PhoenixProfilerTest.EndpointDisabled)

      assert Utils.conn_or_socket_config(conn) == [enabled?: false]
    end

    test "returns the endpoint config for a socket" do
      socket = %Phoenix.LiveView.Socket{endpoint: PhoenixProfilerTest.Endpoint}

      assert Utils.conn_or_socket_config(socket) == []
    end

    test "returns nil when the endpoint is not configured" do
      socket = %Phoenix.LiveView.Socket{endpoint: PhoenixProfilerTest.EndpointNotConfigured}

      assert Utils.conn_or_socket_config(socket) == nil
    end
  end

  describe "elements/0" do
    test "returns the built-in elements" do
      assert Utils.elements() == [
               PhoenixProfiler.Elements.Request,
               PhoenixProfiler.Elements.RequestDuration,
               PhoenixProfiler.Elements.MemoryUsage,
               PhoenixProfiler.Elements.EctoRepoUsage,
               PhoenixProfiler.Elements.LiveExceptions
             ]
    end

    test "appends the configured custom elements" do
      Application.put_env(:phoenix_profiler, :custom_elements, [CustomElement])
      on_exit(fn -> Application.delete_env(:phoenix_profiler, :custom_elements) end)

      assert List.last(Utils.elements()) == CustomElement
    end
  end
end
