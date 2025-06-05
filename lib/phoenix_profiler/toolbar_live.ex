defmodule PhoenixProfiler.ToolbarLive do
  # The LiveView for the Web Debug Toolbar
  @moduledoc false
  use Phoenix.LiveView, container: {:div, [class: "phxprof-toolbar-view"]}

  alias PhoenixProfiler.Server
  alias PhoenixProfiler.Utils

  require Logger

  @toolbar_css Application.app_dir(:phoenix_profiler, "priv/static/toolbar.css")
               |> File.read!()
  @toolbar_js Application.app_dir(:phoenix_profiler, "priv/static/toolbar.js")
              |> File.read!()

  def toolbar(assigns) do
    assigns =
      assigns
      |> Map.put(:toolbar_css, @toolbar_css)
      |> Map.put(:toolbar_js, @toolbar_js)

    ~H"""
    <!-- START Phoenix Web Debug Toolbar -->
    <div {@toolbar_attrs}>
      <div class="phxprof-minitoolbar">
        <button
          class="show-button"
          type="button"
          id={"phxprof-toolbar-show-#{@token}"}
          title="Show Toolbar"
          accesskey="D"
          aria-expanded="true"
          aria-controls={"phxprof-toolbar-main-#{@token}"}
        >
        </button>
      </div>
      {live_render(@conn, __MODULE__, session: @session)}
    </div>
    <script>
      <%= Phoenix.HTML.raw(@toolbar_js) %>
    </script>
    <style type="text/css">
      <%= Phoenix.HTML.raw(@toolbar_css) %>
    </style>
    <!-- END Phoenix Web Debug Toolbar -->
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= for {element, assigns} <- @elements_assigns do %>
      {element.render(assigns)}
    <% end %>

    <div class="phxprof-toolbar-spacer" />

    <.system_element token={@token} system={@system} />
    <.hide_button token={@token} />
    """
  end

  defp system_element(assigns) do
    ~H"""
    <div class="phxprof-element" aria-label="Config">
      <div class="phxprof-element-item phxprof-element-phoenix-logo">
        {@system.phoenix}
      </div>

      <div class="phxprof-toolbar-details" style="left: auto; right: 0px">
        <span class="phxprof-item-label">Profiler Token</span>
        <span class="phxprof-item-value">{@token}</span>

        <span class="phxprof-item-label">LiveView Version</span>
        <span class="phxprof-item-value">
          <a href={"https://hexdocs.pm/phoenix_live_view/#{@system.phoenix_live_view}/"}>
            {@system.phoenix_live_view}
          </a>
        </span>

        <span class="phxprof-item-label">Elixir Version</span>
        <span class="phxprof-item-value">
          <a href={"https://hexdocs.pm/elixir/#{@system.elixir}/"}>
            {@system.elixir}
          </a>
        </span>

        <span class="phxprof-item-label">OTP Release</span>
        <span class="phxprof-item-value">
          <a href="https://erlang.org/erldoc">{@system.otp}</a>
        </span>

        <span class="phxprof-item-label">Resources</span>
        <span class="phxprof-item-value">
          <a href={"https://hexdocs.pm/phoenix/#{@system.phoenix}"}>
            Read Phoenix {@system.phoenix} Docs
          </a>
        </span>

        <span class="phxprof-item-label">Help</span>
        <span class="phxprof-item-value">
          <a href="https://hexdocs.pm/phoenix/community.html">Phoenix Community</a>
        </span>

        <span class="phxprof-item-label">Toolbar version</span>
        <span class="phxprof-item-value">
          <a href={"https://hexdocs.pm/phoenix_profiler/#{@system.phoenix_profiler}"}>
            {@system.phoenix_profiler}
          </a>
        </span>
      </div>
    </div>
    """
  end

  defp hide_button(assigns) do
    ~H"""
    <button
      class="hide-button"
      type="button"
      title="Hide Toolbar"
      accesskey="D"
      aria-expanded="true"
      aria-controls={"phxprof-toolbar-main-#{@token}"}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
        <path
          fill-rule="evenodd"
          d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
          clip-rule="evenodd"
        />
      </svg>
    </button>
    """
  end

  @impl Phoenix.LiveView
  def mount(_, %{"_phxprof" => token}, socket) do
    data_entries = Server.get_entries(token)

    socket =
      socket
      |> assign(:system, system_info())
      |> assign(:token, token)
      |> assign_elements_assigns(data_entries)

    if connected?(socket) do
      Server.subscribe(self(), token)
    end

    {:ok, socket, layout: false, temporary_assigns: [system: nil, token: nil]}
  end

  @impl Phoenix.LiveView
  def handle_info({:entries, new_entries}, socket) do
    {:noreply, assign_elements_assigns(socket, new_entries)}
  end

  defp assign_elements_assigns(socket, entries) do
    entries_by_element = Enum.group_by(entries, &elem(&1, 0), &elem(&1, 1))

    element_assigns =
      Utils.elements()
      |> Enum.map(fn element ->
        element_entries = Map.get(entries_by_element, element, [])
        {element, element.entries_assigns(element_entries)}
      end)

    assign(socket, :elements_assigns, element_assigns)
  end

  # Returns a map of system version metadata.
  defp system_info do
    system_versions = %{
      elixir: System.version(),
      otp: System.otp_release()
    }

    deps_versions =
      for app <- [:phoenix, :phoenix_live_view, :phoenix_profiler], into: %{} do
        {app, Application.spec(app)[:vsn]}
      end

    Map.merge(system_versions, deps_versions)
  end
end
