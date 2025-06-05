defmodule PhoenixProfiler.Elements.LiveExceptions do
  use PhoenixProfiler.Element

  @impl PhoenixProfiler.Element
  def render(assigns) do
    ~H"""
    <.element :if={@exits_count > 0} aria-label="Exits">
      <:item>{@exits_count}</:item>

      <:details>
        <.item :for={%{at: at, reason: reason} <- @exits}>
          <:label>{at}</:label>
          <:value>{reason}</:value>
        </.item>
      </:details>
    </.element>
    """
  end

  # TODO When supporting LiveView, support this component
  @impl PhoenixProfiler.Element
  def subscribed_events, do: []

  @impl PhoenixProfiler.Element
  def collect(_event, _measurements, _metadata) do
    nil
  end

  @impl PhoenixProfiler.Element
  def entries_assigns(_entries) do
    %{exits_count: 0, exits: []}
  end
end
