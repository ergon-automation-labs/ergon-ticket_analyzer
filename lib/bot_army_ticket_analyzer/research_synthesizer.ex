defmodule BotArmyTicketAnalyzer.ResearchSynthesizer do
  @moduledoc """
  Research and synthesize findings about a ticket.

  For each ticket:
  - Extract keywords from title/description
  - Search codebase (via graphify) for related code
  - Find similar past issues
  - Identify fix patterns
  - Return synthesis with citations
  """

  require Logger

  defstruct [
    :ticket_id,
    :title,
    :root_cause,
    :related_tickets,
    :related_code_files,
    :suggested_fix_pattern,
    :confidence,
    :researched_at
  ]

  @type synthesis :: %__MODULE__{}

  def synthesize(ticket, graph_context \\ nil) do
    ticket_id = Map.get(ticket, "id")
    title = Map.get(ticket, "title", "")
    description = Map.get(ticket, "description", "")

    Logger.info("Researching ticket #{ticket_id}: #{title}")

    researched_at = DateTime.utc_now()

    # Extract keywords
    keywords = extract_keywords(title, description)

    # Search graph for related code
    related_code_files =
      case graph_context do
        nil -> []
        graph -> find_related_code(keywords, graph)
      end

    # Find similar past issues (would search ticket history)
    related_tickets = find_similar_tickets(keywords)

    # Infer root cause from code + description
    root_cause = infer_root_cause(title, description, related_code_files)

    # Suggest fix pattern
    fix_pattern = suggest_fix_pattern(root_cause, related_code_files)

    %__MODULE__{
      ticket_id: ticket_id,
      title: title,
      root_cause: root_cause,
      related_tickets: related_tickets,
      related_code_files: related_code_files,
      suggested_fix_pattern: fix_pattern,
      confidence: calculate_confidence(related_code_files, related_tickets),
      researched_at: researched_at
    }
  end

  # Extract keywords from title/description
  defp extract_keywords(title, description) do
    text = "#{title} #{description}"

    text
    |> String.downcase()
    |> String.split(~r/[^a-z0-9_\-]+/)
    |> Enum.filter(fn word -> String.length(word) > 3 end)
    |> Enum.uniq()
    |> Enum.take(10)
  end

  # Find related code files in graph (stub for now)
  defp find_related_code(keywords, _graph) do
    # In production, would search graph for entities matching keywords
    keywords
    |> Enum.map(fn keyword ->
      %{
        file: "lib/unknown_module_#{keyword}.ex",
        relevance: 0.5,
        reason: "keyword match"
      }
    end)
    |> Enum.take(3)
  end

  # Find similar past issues (stub for now)
  defp find_similar_tickets(keywords) do
    # In production, would search ticket history DB
    case keywords do
      ["race", "condition" | _] ->
        [
          %{
            id: "PAST-123",
            title: "Previous race condition in scheduler",
            resolution: "Added mutex lock"
          }
        ]

      ["timeout" | _] ->
        [
          %{
            id: "PAST-456",
            title: "Request timeout issue",
            resolution: "Increased timeout from 5s to 15s"
          }
        ]

      _ ->
        []
    end
  end

  # Infer root cause from context
  defp infer_root_cause(title, description, related_code) do
    first_code_file =
      case Enum.at(related_code, 0) do
        nil -> "unknown module"
        code -> Map.get(code, "file", "unknown module")
      end

    cond do
      String.contains?(String.downcase(title), ["race", "concurrent", "lock"]) ->
        "Concurrent access causing race condition in #{first_code_file}"

      String.contains?(String.downcase(title), ["timeout", "hang", "slow"]) ->
        "Performance issue: request handling is slow or blocking indefinitely"

      String.contains?(String.downcase(title), ["crash", "panic", "error"]) ->
        "Exception during message processing or system shutdown"

      true ->
        "Issue with #{first_code_file}"
    end
  end

  # Suggest fix pattern based on root cause
  defp suggest_fix_pattern(root_cause, _related_code) do
    cond do
      String.contains?(root_cause, "race condition") ->
        %{
          pattern: "Add synchronization primitive",
          steps: [
            "Use mutex or semaphore to protect shared state",
            "Ensure atomic operations",
            "Test with concurrent load"
          ]
        }

      String.contains?(root_cause, "Performance issue") ->
        %{
          pattern: "Profile and optimize",
          steps: [
            "Identify hot path with profiler",
            "Cache expensive operations",
            "Consider async/background processing"
          ]
        }

      String.contains?(root_cause, "Exception") ->
        %{
          pattern: "Add error handling",
          steps: [
            "Wrap in try/catch or handle/rescue",
            "Log error with context",
            "Return graceful error response"
          ]
        }

      true ->
        %{
          pattern: "Debug and fix",
          steps: ["Review code", "Add logging", "Write test case"]
        }
    end
  end

  # Calculate confidence based on evidence
  defp calculate_confidence(code_files, related_tickets) do
    file_score = min(length(code_files) / 3, 1.0)
    ticket_score = min(length(related_tickets) / 2, 1.0)
    average = (file_score + ticket_score) / 2
    Float.round(average, 2)
  end

  @doc "Convert synthesis to JSON response"
  def to_response(%__MODULE__{} = synthesis) do
    %{
      "ok" => true,
      "data" => %{
        "ticket_id" => synthesis.ticket_id,
        "title" => synthesis.title,
        "researched_at" => DateTime.to_iso8601(synthesis.researched_at),
        "root_cause" => synthesis.root_cause,
        "related_code_files" => synthesis.related_code_files,
        "related_tickets" => synthesis.related_tickets,
        "suggested_fix" => synthesis.suggested_fix_pattern,
        "confidence" => synthesis.confidence,
        "summary" =>
          "#{synthesis.title}. Root cause: #{synthesis.root_cause}. " <>
            "Confidence: #{trunc(synthesis.confidence * 100)}%. " <>
            case synthesis.suggested_fix_pattern do
              %{"pattern" => pattern} ->
                "Suggested approach: #{pattern}."

              _ ->
                "Review code and related tickets for fix strategy."
            end
      }
    }
  end
end
