defmodule PhoenixProfiler.ServerTest do
  use ExUnit.Case, async: true

  alias PhoenixProfiler.Elements.{MemoryUsage, Request, RequestDuration}
  alias PhoenixProfiler.Server

  defmodule PageLive do
    use Phoenix.LiveView

    def render(assigns), do: ~H""
  end

  @endpoint_stop [:phoenix, :endpoint, :stop]
  @live_view_handle_event_stop [:phoenix, :live_view, :handle_event, :stop]

  # Emits the event `Plug.Telemetry` sends at the end of a request.
  defp endpoint_stop(duration) do
    conn =
      :get
      |> Plug.Test.conn("/")
      |> Plug.Conn.put_private(:phoenix_endpoint, PhoenixProfilerTest.Endpoint)
      |> Map.put(:status, 200)

    :telemetry.execute(@endpoint_stop, %{duration: duration}, %{conn: conn})
  end

  # Emits the event LiveView sends at the end of a `handle_event/3` callback.
  defp handle_event_stop(duration) do
    socket = %Phoenix.LiveView.Socket{view: PageLive}

    :telemetry.execute(@live_view_handle_event_stop, %{duration: duration}, %{
      socket: socket,
      event: "ping",
      params: %{}
    })
  end

  defp endpoint_durations(token) do
    for {RequestDuration, %{endpoint: duration}} <- Server.get_entries(token), do: duration
  end

  describe "add_observable/1" do
    test "generates a token and stores it in the process dictionary" do
      token = Server.add_observable()

      assert is_binary(token)
      assert Process.get(:phoenix_profiler_token) == token
    end

    test "uses the given token" do
      assert Server.add_observable("my-token") == "my-token"
      assert Process.get(:phoenix_profiler_token) == "my-token"
    end
  end

  describe "get_entries/1" do
    test "returns an empty list for an unknown token" do
      assert Server.get_entries("unknown") == []
    end
  end

  describe "telemetry" do
    test "stores one entry per element subscribed to the event" do
      token = Server.add_observable()
      endpoint_stop(42)

      entries = Server.get_entries(token)

      assert {RequestDuration, %{endpoint: 42}} in entries
      assert {Request, %{conn: %Plug.Conn{status: 200}}} = List.keyfind(entries, Request, 0)
      assert {MemoryUsage, %{memory: memory}} = List.keyfind(entries, MemoryUsage, 0)
      assert memory > 0
    end

    test "appends the entries of the following events" do
      token = Server.add_observable()
      endpoint_stop(1)
      endpoint_stop(2)

      assert endpoint_durations(token) == [1, 2]
    end

    test "ignores events emitted by processes without a token" do
      token = Server.add_observable()
      parent = self()

      spawn(fn ->
        endpoint_stop(1)
        send(parent, :done)
      end)

      assert_receive :done
      assert Server.get_entries(token) == []
    end

    test "finds the token through $callers" do
      token = Server.add_observable()

      Task.async(fn ->
        endpoint_stop(1)
        Task.async(fn -> endpoint_stop(2) end) |> Task.await()
      end)
      |> Task.await()

      assert Enum.sort(endpoint_durations(token)) == [1, 2]
    end

    test "stores the LiveView events" do
      token = Server.add_observable()
      handle_event_stop(2)

      assert [{RequestDuration, %{latest_event: 2}}] = Server.get_entries(token)
    end
  end

  describe "subscribe/2" do
    test "sends all the entries of the token to the subscriber on each event" do
      token = Server.add_observable()
      Server.subscribe(self(), token)

      endpoint_stop(1)
      assert_receive {:entries, entries}
      assert [1] = for({RequestDuration, %{endpoint: d}} <- entries, do: d)

      endpoint_stop(2)
      assert_receive {:entries, entries}
      assert [1, 2] = for({RequestDuration, %{endpoint: d}} <- entries, do: d)
    end

    test "does not notify the subscribers of other tokens" do
      token = Server.add_observable()
      Server.subscribe(self(), "another-token")

      endpoint_stop(1)
      assert Server.get_entries(token) != []
      refute_received {:entries, _}
    end
  end
end
