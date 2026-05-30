defmodule BotArmyTicketAnalyzer.Repo do
  use Ecto.Repo,
    otp_app: :bot_army_ticket_analyzer,
    adapter: Ecto.Adapters.Postgres
end
