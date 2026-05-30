import Config

config :bot_army_ticket_analyzer, :deployment_status, "deployed"

config :bot_army_ticket_analyzer, ecto_repos: [BotArmyTicketAnalyzer.Repo]

config :bot_army_ticket_analyzer, BotArmyTicketAnalyzer.Repo,
  database: "bot_army_ticket_analyzer",
  hostname: "localhost",
  port: 30003,
  username: "postgres",
  password: "postgres"
