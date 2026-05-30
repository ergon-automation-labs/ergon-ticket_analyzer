defmodule BotArmyTicketAnalyzer.TicketSources.LinearSource do
  @moduledoc """
  Linear ticket source. Fetches issues via Linear API.

  Config:
    %{
      "api_key" => "linear-api-key",
      "team_key" => "PROJ",
      "state" => "started,completed"
    }
  """

  @behaviour BotArmyTicketAnalyzer.TicketSources.TicketSource

  @impl true
  def source_name, do: "linear"

  @impl true
  def validate_config(config) do
    required = ["api_key", "team_key"]

    case Enum.filter(required, fn key -> not Map.has_key?(config, key) end) do
      [] -> :ok
      missing -> {:error, "Missing required config: #{Enum.join(missing, ", ")}"}
    end
  end

  @impl true
  def fetch_open_tickets(_config) do
    # TODO: Implement Linear GraphQL integration
    {:ok, []}
  end
end
