# PRM seed data

alias Core.GlobalParameters.GlobalParameter
alias Core.PRMRepo

:core
|> Application.app_dir("priv/prm_repo/fixtures/global_parameters.json")
|> File.read!()
|> Jason.decode!(as: [%GlobalParameter{}])
|> Enum.map(&PRMRepo.insert/1)
