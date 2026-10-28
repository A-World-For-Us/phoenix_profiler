defmodule PhoenixProfiler.Plug do
  @moduledoc false
  import Plug.Conn

  alias PhoenixProfiler.Profiler
  alias PhoenixProfiler.ToolbarLive
  alias PhoenixProfiler.Utils

  @phxprof_token_header "x-phxprof-token"
  @phxprof_token_param "_phxprof_token"

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    if Profiler.enabled?(conn) do
      token = conn_token(conn)

      conn
      |> Profiler.enable(token)
      |> before_send_profile()
    else
      conn
    end
  end

  defp conn_token(conn) do
    case get_req_header(conn, @phxprof_token_header) do
      [] -> nil
      [token | _] -> token
    end
  end

  # HTML Injection
  # Copyright (c) 2018 Chris McCord
  # https://github.com/phoenixframework/phoenix_live_reload/blob/94d1b2f7977c118970f2617fa7fbd8264d39bbc4/lib/phoenix_live_reload/live_reloader.ex#L152
  defp before_send_profile(conn) do
    register_before_send(conn, fn conn ->
      if conn.resp_body != nil and html?(conn) do
        resp_body = IO.iodata_to_binary(conn.resp_body)
        endpoint = conn.private.phoenix_endpoint

        if has_body?(resp_body) and :code.is_loaded(endpoint) do
          {head, [last]} = Enum.split(String.split(resp_body, "</body>"), -1)
          head = Enum.intersperse(head, "</body>")
          body = [head, debug_toolbar_assets_tag(conn), "</body>" | last]
          put_in(conn.resp_body, body)
        else
          conn
        end
      else
        conn
      end
    end)
  end

  defp html?(conn) do
    case get_resp_header(conn, "content-type") do
      [] -> false
      [type | _] -> String.starts_with?(type, "text/html")
    end
  end

  defp has_body?(resp_body), do: String.contains?(resp_body, "<body")

  defp debug_toolbar_assets_tag(conn) do
    config = Utils.conn_or_socket_config(conn) || []

    toolbar_attrs = Keyword.get(config, :toolbar_attrs, [])
    token = conn.private.phoenix_profiler

    attrs =
      Keyword.merge(
        toolbar_attrs,
        class: "phxprof-toolbar",
        "data-token": token,
        role: "region",
        name: "Phoenix Web Debug Toolbar"
      )

    %{
      conn: conn,
      session: %{"_phxprof" => token},
      token: token,
      toolbar_attrs: attrs
    }
    |> ToolbarLive.toolbar()
    |> Phoenix.HTML.Safe.to_iodata()
  end

  @doc false
  def on_mount(_arg, _params, _session, socket) do
    socket =
      if Phoenix.LiveView.connected?(socket) and Profiler.enabled?(socket) do
        Profiler.enable(socket, socket_token(socket))
      else
        socket
      end

    {:cont, socket}
  end

  defp socket_token(socket) do
    socket
    |> Phoenix.LiveView.get_connect_params()
    |> Map.get(@phxprof_token_param, nil)
  end
end
