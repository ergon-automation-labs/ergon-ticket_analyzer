defmodule BotArmyTicketAnalyzer.TicketSources.MockSource do
  @moduledoc "Mock ticket source for testing. Returns sample data."

  @behaviour BotArmyTicketAnalyzer.TicketSources.TicketSource

  @impl true
  def source_name, do: "mock"

  @impl true
  def validate_config(_config) do
    :ok
  end

  @impl true
  def fetch_open_tickets(_config) do
    {:ok, sample_tickets()}
  end

  defp sample_tickets do
    now = DateTime.utc_now()

    [
      %{
        "id" => "PROJ-456",
        "title" => "Fix scheduler startup race condition",
        "status" => "In Progress",
        "priority" => "Critical",
        "assignee" => "alice",
        "due_date" => DateTime.add(now, 86400 * 2) |> DateTime.to_iso8601(),
        "linked_issues" => [
          %{"id" => "PROJ-789", "type" => "blocks"},
          %{"id" => "PROJ-790", "type" => "blocks"}
        ]
      },
      %{
        "id" => "PROJ-789",
        "title" => "Deployment pipeline blocked by PROJ-456",
        "status" => "To Do",
        "priority" => "High",
        "assignee" => "bob",
        "due_date" => DateTime.add(now, 86400) |> DateTime.to_iso8601(),
        "linked_issues" => []
      },
      %{
        "id" => "PROJ-790",
        "title" => "Release v0.2.0 blocked by PROJ-456",
        "status" => "To Do",
        "priority" => "High",
        "assignee" => "charlie",
        "due_date" => DateTime.add(now, 86400 * 3) |> DateTime.to_iso8601(),
        "linked_issues" => []
      },
      %{
        "id" => "PROJ-111",
        "title" => "Overdue: Fix logging in auth handler",
        "status" => "To Do",
        "priority" => "Medium",
        "assignee" => "diana",
        "due_date" => DateTime.add(now, -86400 * 2) |> DateTime.to_iso8601(),
        "linked_issues" => []
      },
      %{
        "id" => "PROJ-222",
        "title" => "Refactor admin dashboard",
        "status" => "Backlog",
        "priority" => "Low",
        "assignee" => nil,
        "linked_issues" => []
      }
    ]
  end
end
