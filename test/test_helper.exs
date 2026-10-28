endpoint_config = [
  url: [host: "localhost", port: 4000],
  secret_key_base: "LIyk9co9Mt8KowH/g1WeMkufq/9Bz1XuEZMhCZAwnBc7VFKCfkDq/vRw+Xso4Q0q",
  live_view: [signing_salt: "NbA2FdHo"],
  render_errors: [formats: [html: PhoenixProfilerTest.ErrorHTML], layout: false],
  check_origin: false,
  pubsub_server: PhoenixProfilerTest.PubSub
]

# The profiler is enabled: the endpoint has a `:phoenix_profiler` config.
Application.put_env(
  :phoenix_profiler,
  PhoenixProfilerTest.Endpoint,
  endpoint_config ++ [phoenix_profiler: []]
)

# The profiler is explicitly disabled.
Application.put_env(
  :phoenix_profiler,
  PhoenixProfilerTest.EndpointDisabled,
  endpoint_config ++ [phoenix_profiler: [enabled?: false]]
)

# The endpoint has no `:phoenix_profiler` config: the profiler is disabled.
Application.put_env(:phoenix_profiler, PhoenixProfilerTest.EndpointNotConfigured, endpoint_config)

# The profiler is enabled with custom options.
Application.put_env(
  :phoenix_profiler,
  PhoenixProfilerTest.EndpointWithOptions,
  endpoint_config ++
    [
      phoenix_profiler: [
        except_patterns: [["admin"], ["internal", "oban"]],
        toolbar_attrs: [id: "my-toolbar", "data-env": "test"]
      ]
    ]
)

defmodule PhoenixProfilerTest.ErrorHTML do
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

defmodule PhoenixProfilerTest.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :fetch_session
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixProfilerTest do
    pipe_through :browser

    get "/", PageController, :index

    forward "/plug-router", PlugRouter
  end

  scope "/api", PhoenixProfilerTest do
    pipe_through :api

    get "/", APIController, :index
  end
end

defmodule PhoenixProfilerTest.PlugRouter do
  use Plug.Router
  import Phoenix.Controller

  plug :match
  plug :dispatch

  get "/" do
    html(conn, "<html><body>Home</body></html>")
  end

  match _ do
    html(conn, "<html><body>Not Found</body></html>")
  end
end

defmodule PhoenixProfilerTest.PageController do
  use Phoenix.Controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "<html><body><p>Hello, world</p></body></html>")
  end
end

defmodule PhoenixProfilerTest.APIController do
  use Phoenix.Controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"hello":"world"}))
  end
end

defmodule PhoenixProfilerTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_profiler

  plug PhoenixProfiler
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"

  plug PhoenixProfilerTest.Router
end

defmodule PhoenixProfilerTest.EndpointDisabled do
  use Phoenix.Endpoint, otp_app: :phoenix_profiler
end

defmodule PhoenixProfilerTest.EndpointNotConfigured do
  use Phoenix.Endpoint, otp_app: :phoenix_profiler
end

defmodule PhoenixProfilerTest.EndpointWithOptions do
  use Phoenix.Endpoint, otp_app: :phoenix_profiler
end

Supervisor.start_link(
  [
    {Phoenix.PubSub, name: PhoenixProfilerTest.PubSub, adapter: Phoenix.PubSub.PG2},
    PhoenixProfilerTest.Endpoint,
    PhoenixProfilerTest.EndpointDisabled,
    PhoenixProfilerTest.EndpointNotConfigured,
    PhoenixProfilerTest.EndpointWithOptions
  ],
  strategy: :one_for_one
)

# Hide the LiveView mount debug logs.
Logger.configure(level: :warning)

ExUnit.start()
