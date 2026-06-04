# Credo configuration for bot_army_ticket_analyzer

%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Design.AliasUsage, false},
        {Credo.Check.Readability.StringSigils, false},
        {Credo.Check.Refactor.ABCSize, false},
        {Credo.Check.Refactor.Nesting, false},
        {Credo.Check.Readability.UnreadableDigits, false}
      ]
    }
  ]
}
