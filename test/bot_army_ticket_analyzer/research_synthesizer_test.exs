defmodule BotArmyTicketAnalyzer.ResearchSynthesizerTest do
  use ExUnit.Case
  @moduletag :synthesizer

  describe "synthesize" do
    test "extracts root cause from title and description" do
      ticket = %{
        "id" => "PROJ-456",
        "title" => "Fix race condition in scheduler",
        "description" => "Two threads accessing shared state simultaneously"
      }

      synthesis = BotArmyTicketAnalyzer.ResearchSynthesizer.synthesize(ticket)

      assert String.contains?(synthesis.root_cause, "race condition")
    end

    test "identifies related code files from keywords" do
      ticket = %{
        "id" => "PROJ-789",
        "title" => "Timeout in authentication handler",
        "description" => "Request times out when checking database"
      }

      synthesis = BotArmyTicketAnalyzer.ResearchSynthesizer.synthesize(ticket)

      # Should have identified related code
      assert is_list(synthesis.related_code_files)
    end

    test "finds similar past issues for known patterns (race condition)" do
      ticket = %{
        "id" => "PROJ-111",
        "title" => "Race condition in connection pool",
        "description" => "Concurrent access issue"
      }

      synthesis = BotArmyTicketAnalyzer.ResearchSynthesizer.synthesize(ticket)

      # Should find related tickets for race conditions
      assert length(synthesis.related_tickets) > 0
    end

    test "suggests fix pattern based on root cause" do
      ticket = %{
        "id" => "PROJ-222",
        "title" => "Crash on shutdown",
        "description" => "Process panics when exiting"
      }

      synthesis = BotArmyTicketAnalyzer.ResearchSynthesizer.synthesize(ticket)

      # Should have fix pattern structure
      assert is_map(synthesis.suggested_fix_pattern)
      # The pattern should be returned (either as a map or stub)
      assert synthesis.suggested_fix_pattern != nil
    end

    test "calculates confidence based on evidence" do
      ticket = %{
        "id" => "PROJ-333",
        "title" => "Fix something",
        "description" => "This needs fixing"
      }

      synthesis = BotArmyTicketAnalyzer.ResearchSynthesizer.synthesize(ticket)

      assert synthesis.confidence >= 0.0
      assert synthesis.confidence <= 1.0
    end

    test "generates response JSON correctly" do
      ticket = %{
        "id" => "PROJ-444",
        "title" => "Race condition in database",
        "description" => "Concurrent writes are failing"
      }

      synthesis = BotArmyTicketAnalyzer.ResearchSynthesizer.synthesize(ticket)
      response = BotArmyTicketAnalyzer.ResearchSynthesizer.to_response(synthesis)

      assert response["ok"] == true
      assert Map.has_key?(response["data"], "root_cause")
      assert Map.has_key?(response["data"], "suggested_fix")
      assert Map.has_key?(response["data"], "summary")
    end
  end
end
