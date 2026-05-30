defmodule BotArmyTicketAnalyzer.TicketSources.GitHubSource do
  @moduledoc """
  GitHub ticket source. Fetches issues via GitHub API.

  Config:
    %{
      "owner" => "my-org",
      "repo" => "my-repo",
      "token" => "github-token",
      "state" => "open"
    }
  """

  @behaviour BotArmyTicketAnalyzer.TicketSources.TicketSource

  @impl true
  def source_name, do: "github"

  @impl true
  def validate_config(config) do
    required = ["owner", "repo", "token"]

    case Enum.filter(required, fn key -> not Map.has_key?(config, key) end) do
      [] -> :ok
      missing -> {:error, "Missing required config: #{Enum.join(missing, ", ")}"}
    end
  end

  @impl true
  def fetch_open_tickets(_config) do
    # TODO: Implement GitHub API integration
    {:ok, []}
  end
end
