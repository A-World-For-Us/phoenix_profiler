defmodule PhoenixProfiler.Elements.MemoryUsage do
  use PhoenixProfiler.Element

  @impl PhoenixProfiler.Element
  def render(assigns) do
    ~H"""
    <.element :if={@memory} aria-label={"Memory, #{@memory.phrase}"}>
      <:item>
        {@memory.value}
        <.label>{@memory.label}</.label>
      </:item>

      <:details>
        <.item>
          <:label>Memory</:label>
          <:value>{@memory.value} {@memory.label}</:value>
        </.item>
      </:details>
    </.element>
    """
  end

  @impl PhoenixProfiler.Element
  def subscribed_events, do: [[:phoenix, :endpoint, :stop]]

  @impl PhoenixProfiler.Element
  def collect([:phoenix, :endpoint, :stop], _measurements, _metadata) do
    %{memory: process_memory(self())}
  end

  @kB 1_024
  defp process_memory(pid) when is_pid(pid) do
    {:memory, bytes} = Process.info(pid, :memory)
    div(bytes, @kB)
  end

  @impl PhoenixProfiler.Element
  def entries_assigns([]) do
    %{memory: nil}
  end

  def entries_assigns(entries) do
    %{memory: memory} = List.last(entries)

    %{memory: formatted_memory(memory)}
  end

  defp formatted_memory(memory) do
    if memory > 1024 do
      value = memory |> div(1024) |> Integer.to_string()
      %{value: value, label: "MiB", phrase: "#{value} mebibytes"}
    else
      value = Integer.to_string(memory)
      %{value: value, label: "KiB", phrase: "#{value} kibibytes"}
    end
  end
end
