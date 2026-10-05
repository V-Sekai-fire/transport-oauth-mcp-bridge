# transport-oauth-mcp-bridge

An Elixir library that lets MCP clients sign in through an OAuth login that is not itself an MCP authorization server.

## What it is for

It provides the OAuth 2.1 server side an MCP endpoint needs (discovery metadata, dynamic client registration, PKCE and bearer-token enforcement) on top of a code-hosting site's login, and the host application wires those functions into its own router. Every token it issues is a stateless macaroon, so it keeps no database and loses nothing across a restart. The module docs describe each part.

## Build and run

    mix deps.get
    mix test

## Licence

MIT; see `LICENSE`.
