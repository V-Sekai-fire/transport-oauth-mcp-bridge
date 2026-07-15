# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule OAuthMCPBridge.MixProject do
  use Mix.Project

  @version "0.1.0-dev.0"

  def project do
    [
      app: :oauth_mcp_bridge,
      version: @version,
      elixir: "~> 1.17",
      deps: deps(),
      description:
        "A generic OAuth 2.1-to-MCP authorization bridge (GitHub login) — " <>
          "stateless macaroon tokens, no database, survives scale-to-zero restarts.",
      package: package(),
      source_url: "https://github.com/taskweft/oauth-mcp-bridge",
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto]]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/taskweft/oauth-mcp-bridge"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.16"},
      {:plug_crypto, "~> 2.0"},
      {:assent, "~> 0.2.13"},
      {:req, "~> 0.6"},
      {:jason, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
