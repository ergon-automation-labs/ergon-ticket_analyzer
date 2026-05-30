defmodule BotArmyTicketAnalyzer.TicketAnalyzer do
  @moduledoc "Core analysis logic: find blockers, dependencies, SLAs, critical path"

  require Logger

  defstruct [:critical_path, :blockers, :overdue, :dependencies, :analyzed_at]

  @type analysis :: %__MODULE__{}

  # For now, analyze a list of raw ticket maps (from Jira or NATS)
  def analyze_tickets(tickets) when is_list(tickets) do
    analyzed_at = DateTime.utc_now()

    blockers = find_blockers(tickets)
    dependencies = find_dependencies(tickets)
    critical_path = find_critical_path(tickets, dependencies)
    overdue = find_overdue(tickets, analyzed_at)

    %__MODULE__{
      critical_path: critical_path,
      blockers: blockers,
      overdue: overdue,
      dependencies: dependencies,
      analyzed_at: analyzed_at
    }
  end

  # Find tickets that are blocking others
  defp find_blockers(tickets) do
    tickets
    |> Enum.filter(fn ticket ->
      # Look for "blocks" or "is blocked by" relationships
      blockers =
        ticket
        |> Map.get("linked_issues", [])
        |> Enum.any?(fn link ->
          link
          |> Map.get("type", "")
          |> String.downcase()
          |> String.contains?(["blocks", "blocker"])
        end)

      # Or if it's critical and high priority
      critical =
        (Map.get(ticket, "status") == "In Progress" ||
           Map.get(ticket, "status") == "To Do") &&
          (Map.get(ticket, "priority") == "Critical" ||
             Map.get(ticket, "priority") == "Highest")

      blockers or critical
    end)
    |> Enum.map(fn ticket ->
      %{
        id: Map.get(ticket, "id"),
        title: Map.get(ticket, "title"),
        status: Map.get(ticket, "status"),
        priority: Map.get(ticket, "priority"),
        assignee: Map.get(ticket, "assignee"),
        blocks_count:
          ticket
          |> Map.get("linked_issues", [])
          |> Enum.count(fn link ->
            link
            |> Map.get("type", "")
            |> String.downcase()
            |> String.contains?("blocks")
          end)
      }
    end)
    |> Enum.sort_by(fn t -> -t.blocks_count end)
  end

  # Find dependency relationships
  defp find_dependencies(tickets) do
    Enum.reduce(tickets, %{}, fn ticket, deps ->
      ticket_id = Map.get(ticket, "id")
      linked = Map.get(ticket, "linked_issues", [])

      new_deps =
        Enum.reduce(linked, %{}, fn link, acc ->
          link_type = link |> Map.get("type", "") |> String.downcase()
          link_id = Map.get(link, "id")

          if String.contains?(link_type, ["blocks", "depends"]) do
            Map.put(acc, link_id, {:blocked_by, ticket_id})
          else
            acc
          end
        end)

      Map.merge(deps, new_deps)
    end)
  end

  # Find critical path (tickets that unblock the most others)
  defp find_critical_path(tickets, dependencies) do
    ticket_ids = Enum.map(tickets, &Map.get(&1, "id"))

    ticket_ids
    |> Enum.map(fn id ->
      blocked_count =
        dependencies
        |> Enum.count(fn {_, {:blocked_by, blocker_id}} -> blocker_id == id end)

      {id, blocked_count}
    end)
    |> Enum.filter(fn {_, count} -> count > 0 end)
    |> Enum.sort_by(fn {_, count} -> -count end)
    |> Enum.map(fn {id, count} ->
      ticket = Enum.find(tickets, fn t -> Map.get(t, "id") == id end)

      %{
        id: id,
        title: Map.get(ticket, "title"),
        unblocks_count: count,
        priority: Map.get(ticket, "priority"),
        status: Map.get(ticket, "status")
      }
    end)
  end

  # Find overdue tickets (SLA violations)
  defp find_overdue(tickets, now) do
    tickets
    |> Enum.filter(fn ticket ->
      due_date_str = Map.get(ticket, "due_date")

      case due_date_str do
        nil ->
          false

        due_date ->
          case DateTime.from_iso8601(due_date) do
            {:ok, due_dt, _offset} -> DateTime.compare(due_dt, now) == :lt
            _ -> false
          end
      end
    end)
    |> Enum.map(fn ticket ->
      %{
        id: Map.get(ticket, "id"),
        title: Map.get(ticket, "title"),
        due_date: Map.get(ticket, "due_date"),
        priority: Map.get(ticket, "priority"),
        assignee: Map.get(ticket, "assignee"),
        days_overdue:
          case DateTime.from_iso8601(Map.get(ticket, "due_date", "")) do
            {:ok, due_dt, _} ->
              diff = DateTime.diff(now, due_dt, :day)
              max(0, diff)

            _ ->
              0
          end
      }
    end)
    |> Enum.sort_by(fn t -> -t.days_overdue end)
  end

  @doc "Convert analysis to JSON for NATS response"
  def to_response(%__MODULE__{} = analysis) do
    %{
      "ok" => true,
      "data" => %{
        "analyzed_at" => DateTime.to_iso8601(analysis.analyzed_at),
        "critical_path" => analysis.critical_path,
        "blockers" => analysis.blockers,
        "overdue" => analysis.overdue,
        "summary" => %{
          "critical_count" => length(analysis.critical_path),
          "blockers_count" => length(analysis.blockers),
          "overdue_count" => length(analysis.overdue),
          "recommendation" =>
            case analysis.critical_path do
              [first | _] -> "Start with #{first.id} (unblocks #{first.unblocks_count})"
              [] -> "No critical path identified. Pick by priority."
            end
        }
      }
    }
  end
end
