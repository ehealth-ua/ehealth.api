# PRM seed data

alias EHealth.PRM.GlobalParameters.Schema, as: GlobalParameter
alias EHealth.PRMRepo

"priv/prm_repo/fixtures/global_parameters.json"
|> File.read!
|> Poison.decode!(as: [%GlobalParameter{}])
|> Enum.map(&PRMRepo.insert/1)
