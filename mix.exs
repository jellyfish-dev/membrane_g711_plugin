defmodule Membrane.G711.Plugin.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/jellyfish-dev/membrane_g711_plugin"

  def project do
    [
      app: :membrane_g711_plugin,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),

      # hex
      description: "Membrane G711 decoder, encoder and parser",
      package: package(),

      # docs
      name: "Membrane G711 Plugin",
      source_url: @github_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:benchmark), do: ["lib", "benchmarks"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:membrane_core, "~> 1.0"},
      {:membrane_g711_format, "~> 0.1.0"},
      {:membrane_raw_audio_format, "~> 0.12.0"},

      # Test deps
      {:membrane_file_plugin, "~> 0.16.0", only: :test},
      {:membrane_raw_audio_parser_plugin, "~> 0.4.0", only: :test},

      # Dev deps
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},

      # Benchmark deps
      {:benchee, "~> 1.0", only: :benchmark},
      {:membrane_g711_ffmpeg_plugin, "~> 0.1.1", only: :benchmark}
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membrane.stream"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      formatters: ["html"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.G711]
    ]
  end
end
