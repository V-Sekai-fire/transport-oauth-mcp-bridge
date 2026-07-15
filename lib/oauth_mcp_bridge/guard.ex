# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule OAuthMCPBridge.Guard do
  @moduledoc """
  Bearer-token enforcement for the MCP endpoint. Which paths need the guard is
  app-specific route knowledge, so this only provides the check itself — call
  `require_bearer/1` from your own router on whichever paths you gate:

      defp mcp_guard(conn, _opts) do
        if public_path?(conn), do: conn, else: OAuthMCPBridge.Guard.require_bearer(conn)
      end
  """

  import Plug.Conn

  alias OAuthMCPBridge.{BaseURL, OAuth}

  @doc """
  Require a valid `Authorization: Bearer <token>` header; on success, assigns
  `:github_login` on the conn. On failure, sends a 401 with a
  `WWW-Authenticate` header pointing at the protected-resource metadata (so
  clients discover the OAuth flow) and halts the conn.
  """
  @spec require_bearer(Plug.Conn.t()) :: Plug.Conn.t()
  def require_bearer(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, login} <- OAuth.verify_access(token) do
      assign(conn, :github_login, login)
    else
      _ -> unauthorized(conn)
    end
  end

  @doc "Send the 401 + WWW-Authenticate response directly (rarely needed outside `require_bearer/1`)."
  @spec unauthorized(Plug.Conn.t()) :: Plug.Conn.t()
  def unauthorized(conn) do
    resource = BaseURL.get(conn) <> "/.well-known/oauth-protected-resource"

    conn
    |> put_resp_header(
      "www-authenticate",
      ~s(Bearer resource_metadata="#{resource}", error="invalid_token")
    )
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{"error" => "invalid_token"}))
    |> halt()
  end
end
