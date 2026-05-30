defmodule BotArmyTicketAnalyzer.NATS.Handler do
  @moduledoc "Handle analysis requests on bot_army.analysis.tickets.overnight"

  require Logger

  def handle_overnight_analysis_request(body) do
    case Jason.decode(body) do
      {:ok, params} ->
        perform_analysis(params)

      {:error, err} ->
        Logger.warning("Failed to parse analysis request: #{inspect(err)}")
        error_response("invalid_request", "Failed to parse request body")
    end
  end

  defp perform_analysis(params) do
    # Can be called in two ways:
    # 1. With explicit test_tickets in request (for testing)
    # 2. With source config (jira, github, linear, etc.)
    case {Map.get(params, "test_tickets"), Map.get(params, "source")} do
      {test_tickets, nil} when is_list(test_tickets) and test_tickets != [] ->
        # Direct test data
        analyze_and_respond(test_tickets)

      {nil, source_config} when is_map(source_config) ->
        # Fetch from configured source
        fetch_and_analyze(source_config)

      _ ->
        # Default: use mock source
        fetch_and_analyze(%{"type" => "mock"})
    end
  end

  defp fetch_and_analyze(source_config) do
    source_type = Map.get(source_config, "type", "mock")

    source_module =
      case source_type do
        "jira" -> BotArmyTicketAnalyzer.TicketSources.JiraSource
        "github" -> BotArmyTicketAnalyzer.TicketSources.GitHubSource
        "linear" -> BotArmyTicketAnalyzer.TicketSources.LinearSource
        _ -> BotArmyTicketAnalyzer.TicketSources.MockSource
      end

    case BotArmyTicketAnalyzer.TicketSources.TicketSource.fetch(source_module, source_config) do
      {:ok, tickets} ->
        analyze_and_respond(tickets)

      {:error, reason} ->
        error_response("fetch_failed", "Failed to fetch tickets: #{inspect(reason)}")
    end
  end

  defp analyze_and_respond(tickets) do
    analysis = BotArmyTicketAnalyzer.TicketAnalyzer.analyze_tickets(tickets)
    BotArmyTicketAnalyzer.TicketAnalyzer.to_response(analysis) |> Jason.encode!()
  end

  defp error_response(error, message) do
    %{
      "ok" => false,
      "error" => error,
      "message" => message,
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
    }
    |> Jason.encode!()
  end
end
