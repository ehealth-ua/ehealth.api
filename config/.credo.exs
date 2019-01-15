%{
  configs: [
    %{
      color: true,
      name: "default",
      files: %{
        included: ["apps/*/lib/*"],
        excluded: ["apps/*/lib/tasks/tasks.ex", "apps/*/lib/kafka_tasks/kafka_tasks.ex"]
      },
      checks: [
        {Credo.Check.Design.DuplicatedCode, false},
        {Credo.Check.Design.TagTODO, exit_status: 0},
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 120},
        {Credo.Check.Readability.Specs, false},
        {Credo.Check.Design.AliasUsage, if_nested_deeper_than: 2}
      ]
    }
  ]
}
