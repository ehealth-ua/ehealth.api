# PRM seed data

alias EHealth.GlobalParameters.GlobalParameter
alias EHealth.PRMRepo

:ehealth
|> Application.app_dir("priv/prm_repo/fixtures/global_parameters.json")
|> File.read!()
|> Jason.decode!(as: [%GlobalParameter{}])
|> Enum.map(&PRMRepo.insert/1)
