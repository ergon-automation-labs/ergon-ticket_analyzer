defmodule BotArmyTicketAnalyzer.TicketSources.TicketSource do
  @moduledoc """
  Generic interface for fetching tickets from various sources.

  Implementations:
  - JiraSource
  - GitHubSource
  - GitLabSource
  - LinearSource
  - MockSource (for testing)
  """

  @callback fetch_open_tickets(config :: map()) :: {:ok, list(map())} | {:error, term()}
  @callback validate_config(config :: map()) :: :ok | {:error, term()}
  @callback source_name() :: String.t()

  def fetch(source_module, config) do
    with :ok <- source_module.validate_config(config) do
      source_module.fetch_open_tickets(config)
    end
  end
end
