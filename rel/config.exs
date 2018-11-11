use Mix.Releases.Config,
  default_release: :default,
  default_environment: :default

environment :default do
  set(dev_mode: false)
  set(include_erts: true)
  set(include_src: false)

  set(
    overlays: [
      {:template, "rel/templates/vm.args.eex", "releases/<%= release_version %>/vm.args"}
    ]
  )
end

release :ehealth do
  set(pre_start_hook: "bin/hooks/pre-start-ehealth.sh")
  set(version: current_version(:ehealth))

  set(
    applications: [
      ehealth: :permanent
    ]
  )
end

release :casher do
  set(version: current_version(:casher))

  set(
    applications: [
      casher: :permanent
    ]
  )
end

release :graphql do
  set(pre_start_hook: "bin/hooks/pre-start-graphql.sh")
  set(version: current_version(:graphql))

  set(
    applications: [
      graphql: :permanent
    ]
  )
end

release :merge_legal_entities_consumer do
  set(version: current_version(:merge_legal_entities_consumer))

  set(
    applications: [
      merge_legal_entities_consumer: :permanent
    ]
  )
end
