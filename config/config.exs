import Config

# Logger with correlation_id support
config :logger,
  level: :info,
  backends: [:console],
  default_formatter: {BotArmyRuntime.LoggerFormatter, []}

config :logger, :console,
  format: {BotArmyRuntime.LoggerFormatter, []},
  metadata: [:correlation_id]

config :bot_army_ticket_analyzer, :deployment_status, "deployed"

config :bot_army_ticket_analyzer, ecto_repos: [BotArmyTicketAnalyzer.Repo]

config :bot_army_ticket_analyzer, BotArmyTicketAnalyzer.Repo,
  database: "bot_army_ticket_analyzer",
  hostname: "localhost",
  port: 30003,
  username: "postgres",
  password: "postgres"

