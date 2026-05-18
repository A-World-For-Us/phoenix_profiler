defmodule PhoenixProfiler.MixProject do
  use Mix.Project

  @version "1.1.0"

  def project do
    [
      app: :phoenix_profiler,
      version: @version,
      elixir: "~> 1.14",
      deps: deps(),
      docs: docs(),
      package: package(),
      homepage_url: "https://github.com/mcrumm/phoenix_profiler",
      description: "Phoenix Web Profiler & Debug Toolbar"
    ]
  end

  def application do
    [
      mod: {PhoenixProfiler.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 1.0"}
    ]
  end

  defp docs do
    [
      main: "PhoenixProfiler",
      source_ref: "v#{@version}",
      source_url: "https://github.com/mcrumm/phoenix_profiler"
    ]
  end

  defp package do
    [
      maintainers: ["Michael Allen Crumm Jr."],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/mcrumm/phoenix_profiler",
        "Sponsor" => "https://github.com/sponsors/mcrumm"
      },
      files: ~w(lib priv CHANGELOG.md LICENSE mix.exs README.md)
    ]
  end
end
