defmodule PhoenixProfiler.OnMountTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias PhoenixProfiler.Elements.RequestDuration
  alias PhoenixProfiler.Server

  @endpoint PhoenixProfilerTest.Endpoint

  defmodule PageLive do
    use Phoenix.LiveView

    on_mount PhoenixProfiler

    def render(assigns) do
      ~H"<div>hello</div>"
    end

    def handle_event("ping", _params, socket) do
      {:noreply, socket}
    end

    def handle_call(:token, _from, socket) do
      {:reply, socket.private[:phoenix_profiler], socket}
    end
  end

  test "enables the profiler with the token sent in the connect params" do
    conn = put_connect_params(build_conn(), %{"_phxprof_token" => "page-token"})
    {:ok, view, _html} = live_isolated(conn, PageLive)

    assert GenServer.call(view.pid, :token) == "page-token"
  end

  test "generates a token when the connect params have none" do
    {:ok, view, _html} = live_isolated(build_conn(), PageLive)

    assert is_binary(GenServer.call(view.pid, :token))
  end

  test "stores the LiveView events under the token" do
    conn = put_connect_params(build_conn(), %{"_phxprof_token" => "events-token"})
    {:ok, view, _html} = live_isolated(conn, PageLive)

    render_click(view, "ping", %{})

    assert [{RequestDuration, %{latest_event: duration}}] = Server.get_entries("events-token")
    assert duration > 0
  end
end
