# PhoenixProfiler

<!-- MDOC -->
Provides a **development tool** that gives detailed information about the execution of any request.

**Never** enable it on production servers as it exposes sensitive data about your web application.

## Built-in Features

* Request/Response - status code, params, headers, cookies, etc.

* Routing - endpoint, router, controller/live view, action, etc.

* Basic diagnostics - response time, memory

* Inspect LiveView crashes (Coming Soon)

* Inspect Ecto queries and detect N+1 queries.

* Swoosh mailer integration (Coming Soon)


<!-- * Custom elements TODO Document  -->

## Installation

To start using the profiler, you will need the following steps:

1. Add and configure the `phoenix_profiler` dependency
2. Enable the profiler on your Endpoint
3. Configure LiveView
4. Add the `PhoenixProfiler` plug
5. Mount the profiler on your LiveViews (optional)
6. Send the profiler token in you AJAX requests (recommended)
<!-- 7. Add the profiler page on your LiveDashboard (optional) -->

### 1. Add the phoenix_profiler dependency

Add phoenix_profiler to your `mix.exs`:

```elixir
{:phoenix_profiler, "~> 0.4.0"}
```

If you're using Ecto, configure the repositories you want the profiler to listen to

```elixir
config :phoenix_profiler,
  ecto_repos: [MyApp.Repo],
  enabled?: true
```

Additionaly, you can configure the N+1 detector to only show stacktraces from said modules.
```elixir
config :phoenix_profiler,
  ecto_repos: [MyApp.Repo],
  enabled?: true,
  filter_on_modules: [Demo, DemoWeb]
```

### 2. Enable the profiler on your Endpoint

PhoenixProfiler is disabled by default. In order to enable it,
you must update your endpoint's `:dev` configuration to include the
`:phoenix_profiler` option:

```elixir
# config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  phoenix_profiler: []
```

Most of the `:phoenix_profiler` configuration is endpoint dependant.

The following options are available:

* `:enable` - When set to `false`, disables profiling by default. You can
  always enable profiling on a request via `enable/1`. Defaults to `true`.

* `:except_patterns` - A list of path where the profiler should not be
  enabled. Defaults to `[["phoenix", "live_reload", "frame"]]`. If you
  override it, make sure to include the default patterns. All paths
  that starts with the given pattern will be excluded.

* `:toolbar_attrs` - HTML attributes to be given to the element
  injected for the toolbar. Expects a keyword list of atom keys and
  string values. Defaults to `[]`.

### 3. Configure LiveView

> If LiveView is already installed in your app, you may skip this section.

The Phoenix Web Debug Toolbar is built on top of LiveView. If you plan to use LiveView in your application in the future we recommend you follow [the official installation instructions](https://hexdocs.pm/phoenix_live_view/installation.html).
This guide only covers the minimum steps necessary for the toolbar itself to run.

Update your endpoint's configuration to include a signing salt. You can generate a signing salt by running `mix phx.gen.secret 32` (note Phoenix v1.5+ apps already have this configuration):

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  live_view: [signing_salt: "SECRET_SALT"]
```

### 4. Add the PhoenixProfiler plug

Add the `PhoenixProfiler` plug within the `code_reloading?`
block on your Endpoint (usually in `lib/my_app_web/endpoint.ex`):

```elixir
  if code_reloading? do
    # plugs...
    plug PhoenixProfiler
  end
```

### 5. Mount the profiler on your LiveViews

Note this section is required only if you are using LiveView, otherwise you may skip it.

Add the profiler hook to the `live_view` function on your
web module (usually in `lib/my_app_web.ex`):

```elixir
  def live_view do
    quote do
      # use...

      on_mount PhoenixProfiler

      # view helpers...
    end
  end
```

Then, in your `app.js`, add the token as a parameter of the `LiveSocket`:

```javascript
// window.getPhxProfToken is defined when the toolbar is displayed
let phxprofToken = window.getPhxProfToken?.();

let liveSocket = new LiveSocket("/live", Socket, {params: {..., _phxprof_token: phxprofToken}})
```

This is all. Run `mix phx.server` and observe the toolbar on your browser requests.

### 6. Send the profiler token in you AJAX requests

Note this section is required only if you are do AJAX calls to your backend in your JavaScript, otherwise you may skip it.

When doing an AJAX call, you need to send an extra `x-phxprof-token` header, with the value of the token you got from the `window.getPhxProfToken` function.

```javascript
let phxprofToken = window.getPhxProfToken?.();

// fetch example
fetch("/api", {
  headers: {
    "x-phxprof-token": phxprofToken
  }
});

// XMLHttpRequest example
let xhr = new XMLHttpRequest();
xhr.open("GET", "/api");
xhr.setRequestHeader("x-phxprof-token", phxprofToken);
xhr.send();

// axios example
axios.get("/api", {
  headers: {
    "x-phxprof-token": phxprofToken
  }
});

// jQuery example
$.ajax({
  url: "/api",
  headers: {
    "x-phxprof-token": phxprofToken
  }
});
```

This will allow the profiler to track the AJAX requests and show their stats on the toolbar as well.

<!--
### 7. Add the profiler page on your LiveDashboard (optional)

Note this section is required for the LiveDashboard integration. If you are
not using LiveDashboard, you may technically skip this step, although it is
highly recommended that you
[install LiveDashboard](https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html#module-installation)
to enjoy all the features of PhoenixProfiler.

Add the dashboard definition to the list of `:additional_pages` on
the [`live_dashboard`](`Phoenix.LiveDashboard.Router.live_dashboard/2`) macro
in your router (usually in `lib/my_app_web/router.ex`):

```elixir
live_dashboard "/dashboard",
  additional_pages: [
    _profiler: {PhoenixProfiler.Dashboard, []}
    # additional pages...
  ]
```
-->

## Troubleshooting

### Exception raised with other on_mount hooks

If after enabling the profiler, you see an error like the
following:

```elixir
** (exit) an exception was raised:
** (RuntimeError) cannot attach hook with id :active_tab on :handle_params because the view was not mounted at the router with the live/3 macro
```

Then you need to add an extra clause on your `on_mount/4` function:

```elixir
def on_mount(_arg, :not_mounted_at_router, _session, socket) do
  {:cont, socket}
end
```

This is true for any handle_params hooks that will be invoked
for LiveView modules not mounted at the router (i.e. via
live_render/3), and the web debug toolbar is no exception.

<!-- MDOC -->

## Contributing

For those planning to contribute to this project, you can run a dev app with the following commands:

    $ mix setup
    $ mix dev

Alternatively, run `iex -S mix dev` if you also want a shell.

## License

MIT License. Copyright (c) 2021 Michael Allen Crumm Jr.
