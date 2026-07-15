# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule OAuthMCPBridge.Whitelist do
  @moduledoc """
  Parses the GitHub-login allowlist config format into the map
  `OAuthMCPBridge.OAuth.check_whitelist/2` expects, ready to
  `:persistent_term.put({:oauth_mcp_bridge, :auth}, ...)`.
  """

  @doc ~S'''
  Parse a comma-separated allowlist: a bare entry is a login, `@name` or
  `org:name` is a public org membership.

      iex> OAuthMCPBridge.Whitelist.parse("fire,@taskweft,org:V-Sekai-fire")
      %{logins: MapSet.new(["fire"]), orgs: MapSet.new(["taskweft", "V-Sekai-fire"])}
  '''
  @spec parse(String.t()) :: %{logins: MapSet.t(), orgs: MapSet.t()}
  def parse(str) when is_binary(str) do
    {orgs, logins} =
      str
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.split_with(&(String.starts_with?(&1, "@") or String.starts_with?(&1, "org:")))

    %{
      logins: MapSet.new(logins),
      orgs:
        orgs
        |> Enum.map(fn o -> o |> String.trim_leading("@") |> String.trim_leading("org:") end)
        |> MapSet.new()
    }
  end
end
