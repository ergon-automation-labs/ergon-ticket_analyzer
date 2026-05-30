defmodule BotArmyTicketAnalyzer.TicketAnalyzerTest do
  use ExUnit.Case
  @moduletag :analyzer

  describe "analyze_tickets" do
    test "finds blockers from ticket relationships" do
      tickets = [
        %{
          "id" => "PROJ-1",
          "title" => "Critical blocker",
          "status" => "In Progress",
          "priority" => "Critical",
          "linked_issues" => [
            %{"id" => "PROJ-2", "type" => "blocks"}
          ]
        },
        %{
          "id" => "PROJ-2",
          "title" => "Blocked task",
          "status" => "To Do",
          "priority" => "High"
        }
      ]

      analysis = BotArmyTicketAnalyzer.TicketAnalyzer.analyze_tickets(tickets)

      assert length(analysis.blockers) > 0
      assert Enum.any?(analysis.blockers, fn b -> b.id == "PROJ-1" end)
    end

    test "identifies critical path (tickets that unblock others)" do
      tickets = [
        %{
          "id" => "PROJ-1",
          "title" => "Unblock others",
          "status" => "In Progress",
          "linked_issues" => [
            %{"id" => "PROJ-2", "type" => "blocks"},
            %{"id" => "PROJ-3", "type" => "blocks"},
            %{"id" => "PROJ-4", "type" => "blocks"}
          ]
        },
        %{
          "id" => "PROJ-2",
          "title" => "Blocked by PROJ-1",
          "status" => "To Do",
          "linked_issues" => []
        },
        %{
          "id" => "PROJ-3",
          "title" => "Also blocked by PROJ-1",
          "status" => "To Do",
          "linked_issues" => []
        },
        %{
          "id" => "PROJ-4",
          "title" => "And blocked by PROJ-1",
          "status" => "To Do",
          "linked_issues" => []
        }
      ]

      analysis = BotArmyTicketAnalyzer.TicketAnalyzer.analyze_tickets(tickets)

      assert length(analysis.critical_path) > 0
      # PROJ-1 should be in critical path (blocks 3 others)
      assert Enum.any?(analysis.critical_path, fn cp -> cp.id == "PROJ-1" end)
    end

    test "finds overdue tickets" do
      now = DateTime.utc_now()
      yesterday = DateTime.add(now, -86400)

      tickets = [
        %{
          "id" => "PROJ-1",
          "title" => "Overdue task",
          "due_date" => DateTime.to_iso8601(yesterday),
          "priority" => "High"
        },
        %{
          "id" => "PROJ-2",
          "title" => "Future task",
          "due_date" => DateTime.to_iso8601(DateTime.add(now, 86400)),
          "priority" => "Low"
        }
      ]

      analysis = BotArmyTicketAnalyzer.TicketAnalyzer.analyze_tickets(tickets)

      assert length(analysis.overdue) == 1
      assert List.first(analysis.overdue).id == "PROJ-1"
    end

    test "generates response JSON correctly" do
      tickets = [
        %{
          "id" => "PROJ-1",
          "title" => "Test task",
          "status" => "In Progress",
          "priority" => "High"
        }
      ]

      analysis = BotArmyTicketAnalyzer.TicketAnalyzer.analyze_tickets(tickets)
      response = BotArmyTicketAnalyzer.TicketAnalyzer.to_response(analysis)

      assert response["ok"] == true
      assert Map.has_key?(response, "data")
      assert Map.has_key?(response["data"], "summary")
      assert Map.has_key?(response["data"]["summary"], "recommendation")
    end

    test "provides recommendation in summary" do
      tickets = [
        %{
          "id" => "PROJ-456",
          "title" => "Unblocks others",
          "status" => "In Progress",
          "linked_issues" => [%{"id" => "PROJ-789", "type" => "blocks"}]
        },
        %{
          "id" => "PROJ-789",
          "title" => "Blocked",
          "status" => "To Do"
        }
      ]

      analysis = BotArmyTicketAnalyzer.TicketAnalyzer.analyze_tickets(tickets)
      response = BotArmyTicketAnalyzer.TicketAnalyzer.to_response(analysis)

      recommendation = response["data"]["summary"]["recommendation"]
      assert String.contains?(recommendation, "PROJ-456")
    end
  end
end
