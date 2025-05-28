defmodule PhoenixProfiler.Elements.Request do
  use PhoenixProfiler.Element

  @impl PhoenixProfiler.Element
  def render(assigns) do
    ~H"""
    <.element aria-label={"Status, #{@status_phrase}"}>
      <:status color={@status_class}>
        {@status_code}
      </:status>

      <:item>
        <.label>@</.label>
        {@router_helper}
      </:item>

      <:details>
        <.item>
          <:label>HTTP status</:label>
          <:value>{@status_code} {@status_phrase}</:value>
        </.item>
        <.item>
          <:label>Plug</:label>
          <:value>{@plug}</:value>
        </.item>
        <.item>
          <:label>Route action</:label>
          <:value>{@action}</:value>
        </.item>
        <.item>
          <:label>Router</:label>
          <:value>{@router}</:value>
        </.item>
        <.item>
          <:label>Endpoint</:label>
          <:value>{@endpoint}</:value>
        </.item>
      </:details>
    </.element>
    """
  end

  @impl PhoenixProfiler.Element
  def subscribed_events, do: [[:phoenix, :endpoint, :stop]]

  @impl PhoenixProfiler.Element
  def collect([:phoenix, :endpoint, :stop], _measurements, metadata) do
    %{conn: metadata.conn}
  end

  @impl PhoenixProfiler.Element
  def entries_assigns([]) do
    %{
      status_phrase: "No Profiler Session (refresh)",
      status_class: "disconnected",
      status_code: ":|",
      router_helper: nil,
      plug: "n/a",
      action: "n/a",
      router: "n/a",
      endpoint: "n/a"
    }
  end

  def entries_assigns(entries) do
    %{conn: conn} = List.last(entries)

    router = conn.private[:phoenix_router]
    {helper, plug, action} = conn_info(conn)

    %{
      status_phrase: Plug.Conn.Status.reason_phrase(conn.status),
      status_class: request_class(conn.status),
      status_code: conn.status,
      router_helper: helper,
      plug: inspect(plug),
      action: inspect(action),
      router: inspect(router),
      endpoint: inspect(conn.private.phoenix_endpoint)
    }
  end

  defp request_class(code) when is_integer(code) do
    case code do
      code when code >= 200 and code < 300 -> :green
      code when code >= 400 and code < 500 -> :red
      code when code >= 500 and code < 600 -> :red
      _ -> nil
    end
  end

  @route_not_found {:route_not_found, nil, nil}
  @router_not_set {:router_not_set, nil, nil}

  # Returns route information from the given `conn`.
  #
  # If no router is set on the conn, returns `@router_not_set`.
  # If the route cannot be determined, returns `@route_not_found`.
  #
  # Otherwise, this function returns a tuple of `{helper, plug_or_live_view, action_or_plug_opts}`.
  defp conn_info(%Plug.Conn{private: %{phoenix_router: router}} = conn) do
    with {:ok, route_info} <- fetch_route_info(router, conn),
         {:ok, routes} <- fetch_routes(router),
         {:ok, route} <- find_route_within_routes(route_info, routes) do
      {route.helper, route.plug, route.plug_opts}
    end
  end

  defp conn_info(%Plug.Conn{}), do: @router_not_set

  defp fetch_route_info(router, conn) do
    case Phoenix.Router.route_info(router, conn.method, conn.request_path, conn.host) do
      %{} = route_info -> {:ok, route_info}
      :error -> @route_not_found
    end
  end

  defp fetch_routes(router) do
    case Phoenix.Router.routes(router) do
      [] -> @route_not_found
      routes -> {:ok, routes}
    end
  end

  defp find_route_within_routes(route_info, routes) do
    if route = Enum.find(routes, &same_route?(&1, route_info)),
      do: {:ok, route},
      else: @route_not_found
  end

  defp same_route?(route, route_info) do
    route.path == route_info.route and
      route.plug == route_info.plug and
      route.plug_opts == route_info.plug_opts
  end
end
