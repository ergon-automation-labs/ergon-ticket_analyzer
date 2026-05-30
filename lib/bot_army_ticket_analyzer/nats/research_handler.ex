defmodule BotArmyTicketAnalyzer.NATS.ResearchHandler do
  @moduledoc "Handle research synthesis requests on bot_army.synthesis.ticket.*"

  require Logger

  def handle_research_request(ticket_id, body) do
    case Jason.decode(body) do
      {:ok, params} ->
        perform_research(ticket_id, params)

      {:error, err} ->
        Logger.warning("Failed to parse research request: #{inspect(err)}")
        error_response("invalid_request", "Failed to parse request body")
    end
  end

  defp perform_research(ticket_id, params) do
    # Check cache first
    case BotArmyTicketAnalyzer.SynthesisCache.get(ticket_id) do
      nil ->
        # Not in cache, perform research
        research_fresh(ticket_id, params)

      cached ->
        # Return cached result
        cached_response(cached)
    end
  end

  defp research_fresh(ticket_id, params) do
    ticket = Map.get(params, "ticket", %{"id" => ticket_id, "title" => ""})
    graph_context = Map.get(params, "graph_context")

    # Perform research and synthesis
    synthesis = BotArmyTicketAnalyzer.ResearchSynthesizer.synthesize(ticket, graph_context)

    # Store in cache
    case BotArmyTicketAnalyzer.SynthesisCache.store(synthesis) do
      {:ok, _cached} ->
        Logger.info("Researched and cached ticket #{ticket_id}")

      {:error, err} ->
        Logger.warning("Failed to cache synthesis for #{ticket_id}: #{inspect(err)}")
    end

    # Return response
    synthesis |> BotArmyTicketAnalyzer.ResearchSynthesizer.to_response() |> Jason.encode!()
  end

  defp cached_response(cached) do
    %{
      "ok" => true,
      "cached" => true,
      "data" => %{
        "ticket_id" => cached.ticket_id,
        "title" => cached.title,
        "root_cause" => cached.root_cause,
        "related_code_files" => cached.related_code_files || [],
        "related_tickets" => cached.related_tickets || [],
        "suggested_fix" => cached.suggested_fix,
        "confidence" => cached.confidence,
        "researched_at" => DateTime.to_iso8601(cached.updated_at),
        "summary" =>
          "#{cached.title}. Root cause: #{cached.root_cause}. " <>
            "Confidence: #{trunc(cached.confidence * 100)}%. (cached)"
      }
    }
    |> Jason.encode!()
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
