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
    # For now, accept a "test_tickets" array in the request
    # In production, this would fetch from Jira API
    tickets = Map.get(params, "test_tickets", [])

    if Enum.empty?(tickets) do
      error_response("no_tickets", "No tickets provided for analysis")
    else
      analysis = BotArmyTicketAnalyzer.TicketAnalyzer.analyze_tickets(tickets)
      BotArmyTicketAnalyzer.TicketAnalyzer.to_response(analysis) |> Jason.encode!()
    end
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
