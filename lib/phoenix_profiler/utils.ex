defmodule PhoenixProfiler.Utils do
  @moduledoc false

  @doc "Get the config of a given `conn` or `socket`."
  def conn_or_socket_config(conn_or_socket) do
    endpoint = conn_or_socket_endpoint(conn_or_socket)
    endpoint.config(:phoenix_profiler, [])
  end

  # Returns the endpoint for a given `conn` or `socket`
  defp conn_or_socket_endpoint(%Plug.Conn{} = conn), do: conn.private.phoenix_endpoint
  defp conn_or_socket_endpoint(%Phoenix.LiveView.Socket{} = socket), do: socket.endpoint

  @library_elements [
                      PhoenixProfiler.Elements.Request,
                      PhoenixProfiler.Elements.RequestDuration,
                      PhoenixProfiler.Elements.MemoryUsage,
                      PhoenixProfiler.Elements.EctoRepoUsage,
                      PhoenixProfiler.Elements.LiveExceptions
                    ]
                    |> Enum.reject(&is_nil/1)

  @doc """
  Return all the elements that can be displayed on the toolbar.

  By default, returns the elements defined in the library.
  Custom elements can be added through the `:custom_elements` config.
  """
  @spec elements() :: [PhoenixProfiler.Element.t()]
  def elements do
    @library_elements ++ Application.get_env(:phoenix_profiler, :custom_elements, [])
  end
end
