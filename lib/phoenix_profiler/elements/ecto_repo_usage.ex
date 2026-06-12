defmodule PhoenixProfiler.Elements.EctoRepoUsage do
  use PhoenixProfiler.Element

  # TODO : First part should be dedicated to SQL queries only
  # N+1 detection can be centered around stacktraces
  # N+1 detection could be zoomed in a popup but it can represent a lot of HTML to render additionnaly, not sure what the politic is around this
  @n_plus_one_repetition_threshold 5

  @impl PhoenixProfiler.Element
  def render(assigns) do
    ~H"""
    <.element aria-label={"Queries, #{@duration.phrase}"}>
      <:item>
        <a href="#" id="show-dialog">
          {@count}
          <.label>in</.label>
          {@duration.value}
          <.label>{@duration.label}</.label>
          <.label>•</.label>
          {@total_data_size}

          <span :if={@possible_n_plus_one == true}>Possible N+1 issue</span>
        </a>
      </:item>
      <:details>
        <.item>
          <:label>Database Queries</:label>
          <:value>{@count}</:value>
        </.item>
        <.item>
          <:label>Different statements</:label>
          <:value>{@unique_queries_count}</:value>
        </.item>
        <.item>
          <:label>Total time</:label>
          <:value>{@duration.value} {@duration.label}</:value>
        </.item>
        <.item>
          <:label>Data loaded</:label>
          <:value>{@total_data_size}</:value>
        </.item>
      </:details>
    </.element>
    <dialog id="phxprof--stacktrace" class="phxprof-dialog">
      <div class="phxprof-dialog-header">
        <h2 class="phxprof-dialog-title">Database Queries</h2>
        <span class="phxprof-dialog-meta">
          {@count} total &middot; {@unique_queries_count} unique &middot; {@total_data_size} loaded
        </span>
        <button class="phxprof-dialog-close" id="close-dialog" aria-label="Close">&times;</button>
      </div>
      <div class="phxprof-query-table-header">
        <span>Source</span>
        <span>Query</span>
        <button class="phxprof-sort-btn" data-sort-col="count">
          Exec. <span class="phxprof-sort-icon">▼</span>
        </button>
        <button class="phxprof-sort-btn" data-sort-col="time">
          Time <span class="phxprof-sort-icon"></span>
        </button>
        <button class="phxprof-sort-btn" data-sort-col="data">
          Data <span class="phxprof-sort-icon"></span>
        </button>
      </div>
      <div id="query_list" class="phxprof-query-list">
        <%= for query <- @queries do %>
          <details class="phxprof-query-row">
            <summary class="phxprof-query-summary">
              <span class="phxprof-query-source">{query.source}</span>
              <span class="phxprof-query-sql">
                <span :if={query.possible_n_plus_one} class="phxprof-n-plus-one-badge">N+1</span>
                {String.slice(query.query, 0..100)}
              </span>
              <span class="phxprof-query-count" data-sort-value={query.execution_count}>
                {query.execution_count}&times;
              </span>
              <span class="phxprof-query-time" data-sort-value={query.total_time_us}>
                {query.total_time.value} {query.total_time.label}
              </span>
              <span class="phxprof-query-data" data-sort-value={query.total_data_size}>
                {query.formatted_data_size}
              </span>
            </summary>
            <div class="phxprof-query-detail">
              <div>
                <span class="phxprof-query-detail-label">Full Query</span>
                <code class="phxprof-query-code">{query.query}</code>
              </div>
              <details class="phxprof-stacktrace-toggle">
                <summary class="phxprof-stacktrace-summary">Stacktrace</summary>
                <div class="phxprof-query-stacktrace">
                  <%= for stack_entry <- clean_stacktrace(query.stacktrace) do %>
                    <span>{Exception.format_stacktrace_entry(stack_entry)}</span>
                  <% end %>
                </div>
              </details>
            </div>
          </details>
        <% end %>
      </div>
    </dialog>
    """
  end

  @impl PhoenixProfiler.Element
  def subscribed_events do
    Application.get_env(:phoenix_profiler, :ecto_repos, [])
    |> Enum.map(&telemetry_event/1)
  end

  defp telemetry_event(repo) do
    telemetry_prefix =
      Keyword.get_lazy(repo.config(), :telemetry_prefix, fn -> telemetry_prefix(repo) end)

    telemetry_prefix ++ [:query]
  end

  defp telemetry_prefix(repo) do
    repo
    |> Module.split()
    |> Enum.map(&(&1 |> Macro.underscore() |> String.to_atom()))
  end

  @impl PhoenixProfiler.Element
  def collect([_app, _repo, :query], measurements, metadata) do
    # Available metrics in `measurements`:
    # :idle_time - the time the connection spent waiting before being checked out for the query
    # :queue_time - the time spent waiting to check out a database connection
    # :query_time - the time spent executing the query
    # :decode_time - the time spent decoding the data received from the database
    # :total_time - the sum of (queue_time, query_time, and decode_time)️

    %{
      measurements: measurements,
      query: metadata.query,
      source: metadata.source,
      repo: metadata.repo,
      stacktrace: metadata.stacktrace,
      data_size: measure_result_size(metadata[:result])
    }
  end

  defp measure_result_size({:ok, result}) do
    word_size = :erlang.system_info(:wordsize)
    :erts_debug.flat_size(result) * word_size
  end

  defp measure_result_size(_), do: 0

  @impl PhoenixProfiler.Element
  def entries_assigns(entries) do
    total_duration = entries |> Stream.map(& &1.measurements.total_time) |> Enum.sum()
    total_data_size = entries |> Enum.sum_by(& &1.data_size)
    aggregated_queries = aggregate_data_for_unique_queries(entries)

    %{
      count: length(entries),
      unique_queries_count: length(aggregated_queries),
      duration: formatted_duration(total_duration),
      total_data_size: format_bytes(total_data_size),
      queries: aggregated_queries,
      possible_n_plus_one: possible_n_plus_one?(Enum.at(aggregated_queries, 0))
    }
  end

  defp possible_n_plus_one?(%{execution_count: exec_count}),
    do: exec_count > @n_plus_one_repetition_threshold

  defp possible_n_plus_one?(_), do: false

  # This should yield a list of maps
  # %{
  #    query: <SQL Query executed>,
  #    stacktrace: <Stack trace executing the query>,
  #    exec_count: <Number of execution of the query / stacktrace>
  #    total_time: <Total time spent to execute the <exec_count> queries>
  #  }
  #
  defp aggregate_data_for_unique_queries(entries) do
    unique_entries = entries |> Enum.uniq_by(&{&1.query, &1.stacktrace})

    unique_entries
    |> Enum.map(fn unique_entry ->
      filtered_entries =
        entries
        |> Enum.filter(
          &(&1.query == unique_entry.query && &1.stacktrace == unique_entry.stacktrace)
        )

      total_time = Enum.sum_by(filtered_entries, & &1.measurements.total_time)
      total_time_us = System.convert_time_unit(total_time, :native, :microsecond)

      total_data_size = Enum.sum_by(filtered_entries, & &1.data_size)

      execution_count = length(filtered_entries)

      Map.merge(unique_entry, %{
        total_time: formatted_duration(total_time),
        total_time_us: total_time_us,
        execution_count: execution_count,
        total_data_size: total_data_size,
        formatted_data_size: format_bytes(total_data_size),
        possible_n_plus_one: execution_count > @n_plus_one_repetition_threshold
      })
    end)
    |> Enum.sort_by(& &1.execution_count, :desc)
  end

  defp clean_stacktrace(nil), do: []

  defp clean_stacktrace(stacktrace) do
    filter_on_modules =
      Enum.map(
        Application.get_env(:phoenix_profiler, :filter_on_modules, []),
        &String.replace(Atom.to_string(&1), "Elixir.", "")
      )

    clean_stacktrace(stacktrace, filter_on_modules)
  end

  defp clean_stacktrace(stacktrace, []), do: stacktrace

  defp clean_stacktrace(stacktrace, filter_on_modules) do
    stacktrace
    |> Enum.reject(fn call ->
      module = elem(call, 0)
      Enum.at(String.split(Atom.to_string(module), "."), 1) not in filter_on_modules
    end)
  end

  defp format_bytes(bytes) when bytes < 1_000, do: "#{bytes} bytes"
  defp format_bytes(bytes) when bytes < 1_000_000, do: "#{Float.round(bytes / 1_000, 1)} KB"

  defp format_bytes(bytes) when bytes < 1_000_000_000,
    do: "#{Float.round(bytes / 1_000_000, 1)} MB"

  defp format_bytes(bytes), do: "#{Float.round(bytes / 1_000_000_000, 1)} GB"

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
