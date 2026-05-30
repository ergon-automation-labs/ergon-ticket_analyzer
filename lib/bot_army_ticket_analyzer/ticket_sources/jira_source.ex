defmodule BotArmyTicketAnalyzer.TicketSources.JiraSource do
  @moduledoc """
  Jira ticket source. Fetches open tickets via Jira API.

  Config:
    %{
      "base_url" => "https://jira.example.com",
      "username" => "bot@example.com",
      "api_token" => "jira-api-token",
      "jql" => "status IN (\"To Do\", \"In Progress\") AND updated >= -7d"
    }
  """

  @behaviour BotArmyTicketAnalyzer.TicketSources.TicketSource

  require Logger

  @impl true
  def source_name, do: "jira"

  @impl true
  def validate_config(config) do
    required = ["base_url", "username", "api_token"]

    case Enum.filter(required, fn key -> not Map.has_key?(config, key) end) do
      [] -> :ok
      missing -> {:error, "Missing required config: #{Enum.join(missing, ", ")}"}
    end
  end

  @impl true
  def fetch_open_tickets(config) do
    base_url = Map.get(config, "base_url")
    username = Map.get(config, "username")
    api_token = Map.get(config, "api_token")
    jql = Map.get(config, "jql", "status IN (\"To Do\", \"In Progress\")")

    url = "#{base_url}/rest/api/3/search"

    headers = [
      {"Authorization", "Basic #{Base.encode64("#{username}:#{api_token}")}"},
      {"Content-Type", "application/json"}
    ]

    query_params = [
      {"jql", jql},
      {"maxResults", "100"},
      {"fields", "key,summary,status,priority,assignee,duedate,issuelinks"}
    ]

    case Req.get(url, headers: headers, params: query_params) do
      {:ok, response} ->
        tickets =
          response.body
          |> Map.get("issues", [])
          |> Enum.map(&parse_jira_issue/1)

        {:ok, tickets}

      {:error, reason} ->
        Logger.error("Failed to fetch Jira tickets: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_jira_issue(issue) do
    fields = Map.get(issue, "fields", %{})

    linked_issues =
      fields
      |> Map.get("issuelinks", [])
      |> Enum.map(fn link ->
        %{
          "id" => get_linked_issue_id(link),
          "type" => get_link_type(link)
        }
      end)

    %{
      "id" => Map.get(issue, "key"),
      "title" => Map.get(fields, "summary", ""),
      "status" => get_status(Map.get(fields, "status", %{})),
      "priority" => get_priority(Map.get(fields, "priority", %{})),
      "assignee" =>
        case Map.get(fields, "assignee") do
          nil -> nil
          assignee -> Map.get(assignee, "displayName")
        end,
      "due_date" => Map.get(fields, "duedate"),
      "linked_issues" => linked_issues
    }
  end

  defp get_status(status_obj) when is_map(status_obj) do
    Map.get(status_obj, "name", "Unknown")
  end

  defp get_status(_), do: "Unknown"

  defp get_priority(priority_obj) when is_map(priority_obj) do
    Map.get(priority_obj, "name", "Unknown")
  end

  defp get_priority(_), do: "Unknown"

  defp get_linked_issue_id(link) when is_map(link) do
    # Try "outwardIssue" first (this issue blocks/relates to), then "inwardIssue"
    case Map.get(link, "outwardIssue") do
      nil -> Map.get(link, "inwardIssue", %{}) |> Map.get("key")
      issue -> Map.get(issue, "key")
    end
  end

  defp get_linked_issue_id(_), do: nil

  defp get_link_type(link) when is_map(link) do
    link
    |> Map.get("type", %{})
    |> Map.get("name", "relates to")
    |> String.downcase()
  end

  defp get_link_type(_), do: "relates to"
end
