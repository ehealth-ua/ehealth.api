use Mix.Releases.Config,
  default_release: :default,
  default_environment: :default

cookie = :sha256
|> :crypto.hash(System.get_env("ERLANG_COOKIE") || "mxxiJ/4jh2gsSDsbGXjHxkCKY0Qp0JRxwFHvU4ovIRwmuQBXtzWXlsY24coV6OIt")
|> Base.encode64

environment :default do
  set pre_start_hook: "bin/hooks/pre-start.sh"
  set dev_mode: false
  set include_erts: false
  set include_src: false
  set cookie: cookie
end

release :ehealth do
  set version: current_version(:ehealth)
  set applications: [
    ehealth: :permanent
  ]
end
