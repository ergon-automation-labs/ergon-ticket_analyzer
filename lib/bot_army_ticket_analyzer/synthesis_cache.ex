defmodule BotArmyTicketAnalyzer.SynthesisCache do
  @moduledoc "Cache research synthesis in PostgreSQL for quick retrieval"

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "synthesis_cache" do
    field(:ticket_id, :string)
    field(:title, :string)
    field(:root_cause, :string)
    field(:related_code_files, {:array, :map})
    field(:related_tickets, {:array, :map})
    field(:suggested_fix, :map)
    field(:confidence, :float)
    field(:expires_at, :utc_datetime)
    timestamps()
  end

  def changeset(cache, attrs) do
    cache
    |> cast(attrs, [
      :ticket_id,
      :title,
      :root_cause,
      :related_code_files,
      :related_tickets,
      :suggested_fix,
      :confidence,
      :expires_at
    ])
    |> validate_required([:ticket_id, :root_cause, :confidence])
    |> unique_constraint(:ticket_id)
  end

  @doc "Store synthesis in cache (expires in 48h)"
  def store(synthesis) do
    expires_at = DateTime.add(DateTime.utc_now(), 48 * 3600)

    attrs = %{
      ticket_id: synthesis.ticket_id,
      title: synthesis.title,
      root_cause: synthesis.root_cause,
      related_code_files: synthesis.related_code_files,
      related_tickets: synthesis.related_tickets,
      suggested_fix: synthesis.suggested_fix_pattern,
      confidence: synthesis.confidence,
      expires_at: expires_at
    }

    %__MODULE__{}
    |> changeset(attrs)
    |> BotArmyTicketAnalyzer.Repo.insert_or_update()
  end

  @doc "Retrieve cached synthesis (returns nil if expired)"
  def get(ticket_id) do
    now = DateTime.utc_now()

    __MODULE__
    |> where([c], c.ticket_id == ^ticket_id)
    |> where([c], c.expires_at > ^now)
    |> BotArmyTicketAnalyzer.Repo.one()
  end

  @doc "Find all unexpired syntheses"
  def all_valid do
    now = DateTime.utc_now()

    __MODULE__
    |> where([c], c.expires_at > ^now)
    |> BotArmyTicketAnalyzer.Repo.all()
  end

  @doc "Delete expired syntheses"
  def cleanup_expired do
    now = DateTime.utc_now()

    __MODULE__
    |> where([c], c.expires_at <= ^now)
    |> BotArmyTicketAnalyzer.Repo.delete_all()
  end
end
