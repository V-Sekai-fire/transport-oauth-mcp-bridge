# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule OAuthMCPBridge.LandingPlug do
  @moduledoc """
  A minimal, static, unauthenticated landing page — not the MCP endpoint
  itself. Dependency-free: no template engine, no JS, just an inlined
  stylesheet.

  ## Configuration

  Set `:persistent_term.put({:oauth_mcp_bridge, :page}, %{...})` before
  starting to customize the copy; all keys are optional:

    * `:title` — page `<title>` and `<h1>` (default `"MCP Server"`)
    * `:tagline` — one-line description under the title
    * `:server_name` — the key inside the example `mcpServers` config
      (default `"mcp"`)
    * `:links` — list of `{label, url}` shown at the bottom
    * `:mcp_path` — path appended to the base URL for the example config
      (default `"/mcp"`)
  """

  @behaviour Plug

  import Plug.Conn
  alias OAuthMCPBridge.BaseURL

  @default_page %{
    title: "MCP Server",
    tagline: "An MCP server gated by GitHub sign-in (OAuth 2.1).",
    server_name: "mcp",
    links: [],
    mcp_path: "/mcp"
  }

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    page = page()
    mcp_url = BaseURL.get(conn) <> page.mcp_path

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html(page, mcp_url))
  end

  defp page do
    :persistent_term.get({:oauth_mcp_bridge, :page}, %{})
    |> then(&Map.merge(@default_page, &1))
  end

  defp html(page, mcp_url) do
    """
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#{page.title}</title>
    <style>
      :root { color-scheme: light dark; }
      body {
        font: 16px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        max-width: 34rem; margin: 4rem auto; padding: 0 1.25rem;
      }
      code, pre { font: 13px/1.5 ui-monospace, Menlo, Consolas, monospace; }
      pre {
        background: color-mix(in srgb, currentColor 6%, transparent);
        padding: .9rem 1rem; border-radius: .5rem; overflow-x: auto;
      }
      a { color: inherit; }
    </style>
    </head>
    <body>
      <h1>#{page.title}</h1>
      <p>#{page.tagline}</p>
      <pre>{ "mcpServers": { "#{page.server_name}": {
      "type": "http",
      "url": "#{mcp_url}"
    } } }</pre>
      <p>No header needed — the client discovers and drives the OAuth flow.</p>
      #{links_html(page.links)}
    </body>
    </html>
    """
  end

  defp links_html([]), do: ""

  defp links_html(links) do
    items = Enum.map_join(links, " · ", fn {label, url} -> ~s(<a href="#{url}">#{label}</a>) end)
    "<p>#{items}</p>"
  end
end
