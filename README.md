<!-- SPDX-License-Identifier: MIT -->
<!-- Copyright (c) 2026 K. S. Ernest (iFire) Lee -->

# oauth-mcp-bridge

A generic OAuth 2.1-to-MCP authorization bridge: lets MCP clients sign in via
GitHub, using standard OAuth 2.1 (RFC 8414 metadata, RFC 7591 dynamic client
registration, PKCE) even though GitHub itself isn't an MCP-compliant
authorization server.

Every OAuth artifact (client_id, state, authorization code, access/refresh
token) is a self-owned, stateless macaroon — no database, no volume; nothing
is lost across a scale-to-zero restart. Extracted from `taskweft/deploy`.

## Modules

- `OAuthMCPBridge.Macaroon` / `OAuthMCPBridge.Artifact` — the stateless token
  primitive.
- `OAuthMCPBridge.OAuth` — the OAuth 2.1 server logic (discovery metadata,
  dynamic client registration, authorize/callback/token endpoints).
- `OAuthMCPBridge.Guard` — bearer-token enforcement for your MCP endpoint.
- `OAuthMCPBridge.BaseURL` — request base-URL resolution (works behind any
  TLS-terminating reverse proxy).
- `OAuthMCPBridge.LandingPlug` — an optional, configurable static landing page.
- `OAuthMCPBridge.Whitelist` — parses a GitHub login/org allowlist string.

## Wiring it up

Configure via `:persistent_term` before your endpoint starts (e.g. in your
`Application.start/2`):

```elixir
:persistent_term.put({:oauth_mcp_bridge, :token_secret}, token_secret)
:persistent_term.put({:oauth_mcp_bridge, :github}, %{client_id: ..., client_secret: ...})
:persistent_term.put({:oauth_mcp_bridge, :auth}, OAuthMCPBridge.Whitelist.parse("fire,@my-org"))
```

Then wire the endpoints into your own `Plug.Router` — this library provides
the logic, not the route table, since which paths are public is app-specific:

```elixir
alias OAuthMCPBridge.{BaseURL, Guard, LandingPlug, OAuth}

plug(:mcp_guard)

get "/" do
  LandingPlug.call(conn, [])
end

get "/.well-known/oauth-protected-resource" do
  send_json(conn, 200, OAuth.protected_resource_metadata(BaseURL.get(conn)))
end

get "/.well-known/oauth-authorization-server" do
  send_json(conn, 200, OAuth.authorization_server_metadata(BaseURL.get(conn)))
end

post "/oauth/register" do
  # decode body, call OAuth.register_client/1
end

get "/oauth/authorize" do
  # call OAuth.authorize/2, redirect to the returned GitHub URL
end

get "/oauth/callback" do
  # call OAuth.callback/2, redirect to the returned client URL
end

post "/oauth/token" do
  # decode body, call OAuth.token/2
end

forward("/mcp", to: YourMCPPlug)

defp mcp_guard(conn, _opts) do
  if public_path?(conn), do: conn, else: Guard.require_bearer(conn)
end
```

See `taskweft/deploy`'s `Router` for a complete, working example.
