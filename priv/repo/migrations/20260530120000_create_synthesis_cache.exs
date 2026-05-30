defmodule BotArmyTicketAnalyzer.Repo.Migrations.CreateSynthesisCache do
  use Ecto.Migration

  def change do
    create table(:synthesis_cache) do
      add(:ticket_id, :string, null: false)
      add(:title, :string)
      add(:root_cause, :string, null: false)
      add(:related_code_files, {:array, :map})
      add(:related_tickets, {:array, :map})
      add(:suggested_fix, :map)
      add(:confidence, :float, null: false)
      add(:expires_at, :utc_datetime, null: false)
      timestamps()
    end

    create(unique_index(:synthesis_cache, [:ticket_id]))
    create(index(:synthesis_cache, [:expires_at]))
  end
end
