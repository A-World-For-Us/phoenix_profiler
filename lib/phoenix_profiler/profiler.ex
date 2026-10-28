defmodule PhoenixProfiler.Profiler do
  @moduledoc false
  alias PhoenixProfiler.Server
  alias PhoenixProfiler.Utils

  @doc """
  Verifies if the profiler is enabled on a given `conn` or `socket`.

  The profiler is enabled when the endpoint has a `:phoenix_profiler`
  configuration, its `:enabled?` option is not `false` and, for a `conn`,
  the request path does not match any of the `:except_patterns`.
  """
  @spec enabled?(receiver) :: boolean() when receiver: Plug.Conn.t() | Phoenix.Socket.t()
  def enabled?(conn_or_socket) do
    case Utils.conn_or_socket_config(conn_or_socket) do
      nil -> false
      config -> enabled_option(config) and not match_except_patterns?(conn_or_socket, config)
    end
  end

  # `:enable` is accepted as an alias of `:enabled?`.
  defp enabled_option(config) do
    Keyword.get_lazy(config, :enabled?, fn -> Keyword.get(config, :enable, true) end)
  end

  @default_except_patterns [["phoenix", "live_reload", "frame"]]

  defp match_except_patterns?(%Plug.Conn{} = conn, config) do
    except_patterns = Keyword.get(config, :except_patterns, @default_except_patterns)

    Enum.any?(except_patterns, fn pattern ->
      List.starts_with?(conn.path_info, pattern)
    end)
  end

  defp match_except_patterns?(%Phoenix.LiveView.Socket{} = _socket, _config), do: false

  @doc """
  Enables the profiler on a given `conn` or `socket`.

  For a LiveView socket, raises if the socket is not connected.
  """
  @spec enable(receiver, token :: String.t()) :: receiver
        when receiver: Plug.Conn.t() | Phoenix.Socket.t()
  def enable(conn_or_socket, token \\ nil) do
    ensure_connected_socket!(conn_or_socket)

    if profile_set?(conn_or_socket) do
      conn_or_socket
    else
      observable_token = Server.add_observable(token)
      set_token(conn_or_socket, observable_token)
    end
  end

  defp ensure_connected_socket!(%Phoenix.LiveView.Socket{} = socket) do
    if Phoenix.LiveView.connected?(socket) do
      :ok
    else
      raise """
      attempted to enable profiling on a disconnected socket

      In your LiveView mount callback, do the following:

          socket =
            if connected?(socket) do
              PhoenixProfiler.enable(socket)
            else
              socket
            end

      """
    end
  end

  defp ensure_connected_socket!(_), do: :ok

  defp profile_set?(conn_or_socket) do
    match?(%{:phoenix_profiler => token} when is_binary(token), conn_or_socket.private)
  end

  defp set_token(%Plug.Conn{} = conn, token),
    do: Plug.Conn.put_private(conn, :phoenix_profiler, token)

  defp set_token(%Phoenix.LiveView.Socket{} = socket, token),
    do: put_in(socket.private[:phoenix_profiler], token)
end
