defmodule PhoenixProfiler.Elements.RequestDuration do
  use PhoenixProfiler.Element

  @impl PhoenixProfiler.Element
  def render(assigns) do
    ~H"""
    <.element :if={@endpoint} aria-label="Durations">
      <:item>
        <.current_duration endpoint={@endpoint} latest_event={@latest_event} />
      </:item>

      <:details>
        <.item :if={@endpoint}>
          <:label>Endpoint Duration</:label>
          <:value>{@endpoint.value}{@endpoint.label}</:value>
        </.item>
        <.item :if={@latest_event}>
          <:label>Latest Event Duration</:label>
          <:value>{@latest_event.value}{@latest_event.label}</:value>
        </.item>
      </:details>
    </.element>
    """
  end

  defp current_duration(assigns) do
    assigns =
      assign_new(assigns, :duration, fn ->
        if event = assigns.latest_event,
          do: event,
          else: assigns.endpoint
      end)

    ~H"""
    {@duration.value}
    <.label>{@duration.label}</.label>
    """
  end

  @impl PhoenixProfiler.Element
  def subscribed_events,
    do: [
      [:phoenix, :endpoint, :stop],
      [:phoenix, :live_view, :handle_event, :stop],
      [:phoenix, :live_component, :handle_event, :stop]
    ]

  @impl PhoenixProfiler.Element
  def collect([:phoenix, :endpoint, :stop], measurements, _metadata) do
    %{endpoint: measurements.duration}
  end

  def collect([:phoenix, live_view_or_component, :handle_event, :stop], measurements, _metadata)
      when live_view_or_component in [:live_view, :live_component] do
    %{latest_event: measurements.duration}
  end

  @impl PhoenixProfiler.Element
  def entries_assigns([]) do
    %{
      endpoint: nil,
      latest_event: nil
    }
  end

  def entries_assigns(entries) do
    data = Enum.reduce(entries, &Map.merge/2)

    %{
      endpoint: formatted_duration(data[:endpoint]),
      latest_event: formatted_duration(data[:latest_event])
    }
  end

  defp formatted_duration(nil), do: nil

  defp formatted_duration(duration) when is_integer(duration) do
    duration = System.convert_time_unit(duration, :native, :microsecond)

    if duration > 1000 do
      value = duration |> div(1000) |> Integer.to_string()
      %{value: value, label: "ms", phrase: "#{value} milliseconds"}
    else
      value = Integer.to_string(duration)
      %{value: value, label: "µs", phrase: "#{value} microseconds"}
    end
  end
end
