# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule OAuthMCPBridgeTest do
  use ExUnit.Case, async: false

  alias OAuthMCPBridge.{Artifact, Macaroon, OAuth, Whitelist}

  setup do
    :persistent_term.put({:oauth_mcp_bridge, :token_secret}, :crypto.strong_rand_bytes(32))
    :ok
  end

  describe "Macaroon" do
    test "mint/verify round-trips and accepts every caveat" do
      m = Macaroon.mint("root", "id", ["a=1", "b=2"])
      encoded = Macaroon.encode(m)
      {:ok, decoded} = Macaroon.decode(encoded)
      assert Macaroon.verify("root", decoded, fn _ -> true end) == {:ok, "id"}
    end

    test "verify fails closed on an unsatisfied caveat" do
      m = Macaroon.mint("root", "id", ["a=1"])
      assert Macaroon.verify("root", m, fn _ -> false end) == {:error, :caveat_unsatisfied}
    end

    test "verify rejects a tampered signature" do
      m = Macaroon.mint("root", "id")
      tampered = %{m | sig: "bad"}
      assert Macaroon.verify("root", tampered, fn _ -> true end) == {:error, :bad_signature}
    end
  end

  describe "Artifact" do
    test "mint/verify round-trips the payload for the right purpose" do
      token = Artifact.mint(:access, %{"sub" => "alice"})
      assert {:ok, %{"sub" => "alice"}} = Artifact.verify(:access, token)
    end

    test "verify rejects a token minted for a different purpose" do
      token = Artifact.mint(:access, %{"sub" => "alice"})
      assert Artifact.verify(:refresh, token) == :error
    end

    test "verify rejects garbage" do
      assert Artifact.verify(:access, "not-a-token") == :error
    end
  end

  describe "Whitelist" do
    test "parses bare logins and @org / org: forms" do
      assert Whitelist.parse("fire,@taskweft,org:V-Sekai-fire") == %{
               logins: MapSet.new(["fire"]),
               orgs: MapSet.new(["taskweft", "V-Sekai-fire"])
             }
    end

    test "empty string parses to empty sets" do
      assert Whitelist.parse("") == %{logins: MapSet.new(), orgs: MapSet.new()}
    end
  end

  describe "OAuth metadata" do
    test "protected_resource_metadata uses the configured mcp_path and service name" do
      :persistent_term.put({:oauth_mcp_bridge, :service}, %{name: "Test Server", mcp_path: "/mcp"})

      meta = OAuth.protected_resource_metadata("https://example.com")
      assert meta["resource"] == "https://example.com/mcp"
      assert meta["resource_name"] == "Test Server"
    end

    test "protected_resource_metadata falls back to generic defaults" do
      :persistent_term.erase({:oauth_mcp_bridge, :service})
      meta = OAuth.protected_resource_metadata("https://example.com")
      assert meta["resource"] == "https://example.com/mcp"
      assert meta["resource_name"] == "MCP Server"
    end

    test "authorization_server_metadata shape" do
      meta = OAuth.authorization_server_metadata("https://example.com")
      assert meta["issuer"] == "https://example.com"
      assert meta["authorization_endpoint"] == "https://example.com/oauth/authorize"
      assert meta["code_challenge_methods_supported"] == ["S256"]
    end
  end

  describe "OAuth.register_client/1" do
    test "mints a client_id for valid redirect_uris" do
      assert {:ok, reg} =
               OAuth.register_client(%{
                 "redirect_uris" => ["https://example.com/redirect"],
                 "client_name" => "test"
               })

      assert is_binary(reg["client_id"])
      assert reg["client_name"] == "test"
    end

    test "rejects a non-http(s) redirect_uri" do
      assert OAuth.register_client(%{"redirect_uris" => ["not-a-uri"]}) ==
               {:error, :invalid_redirect_uri}
    end

    test "rejects missing redirect_uris" do
      assert OAuth.register_client(%{}) == {:error, :invalid_client_metadata}
    end
  end
end
