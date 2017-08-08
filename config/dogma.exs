use Mix.Config
alias Dogma.Rule

config :dogma,
  rule_set: Dogma.RuleSet.All,
  exclude: [
    ~r(\Alib/tasks/tasks.ex), # TODO: https://github.com/lpil/dogma/issues/221
    ~r(\Atest/web/controllers/declaration_request_controller_test.exs),
    ~r(\Atest/integration/creating_declaration_request_test.exs),
    ~r(\Arel/),
    ~r(\Adeps/),
  ],
  override: [
    %Rule.LineLength{ max_length: 120 },
    %Rule.TakenName{ enabled: false }, # TODO: https://github.com/lpil/dogma/issues/201
    %Rule.InfixOperatorPadding{ enabled: false },
    %Rule.FunctionArity{ max: 5 },
  ]
