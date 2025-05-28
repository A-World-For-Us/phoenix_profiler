defmodule PhoenixProfiler.Element do
  use Phoenix.Component

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
      use Phoenix.Component

      import unquote(__MODULE__)
    end
  end

  @callback render(assigns :: map()) :: Phoenix.HTML.safe()

  @callback subscribed_events() :: [event :: any()]

  @callback collect(event :: any(), measurements :: map(), metadata :: map()) :: map()

  @callback entries_assigns([map()]) :: map()

  attr :rest, :global

  slot :status do
    attr :color, :string, values: ["red", "yellow", "green"]
  end

  slot :item, required: true
  slot :details

  def element(assigns) do
    ~H"""
    <div class="phxprof-element" {@rest}>
      <span
        :for={status <- @status}
        class={"phxprof-element-status phxprof-element-status-#{status.color}"}
      >
        {render_slot(status)}
      </span>
      <div class="phxprof-element-item">
        {render_slot(@item)}
      </div>
      <div class="phxprof-toolbar-details">
        {render_slot(@details)}
      </div>
    </div>
    """
  end

  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <span class="phxprof-toolbar-label">
      {render_slot(@inner_block)}
    </span>
    """
  end

  slot :label, required: true
  slot :value, required: true

  def item(assigns) do
    ~H"""
    <span class="phxprof-item-label">{render_slot(@label)}</span>
    <span class="phxprof-item-value">{render_slot(@value)}</span>
    """
  end
end
