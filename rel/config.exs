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

release :deactivate_legal_entity_consumer do
  set(pre_start_hook: "bin/hooks/pre-start-deactivate-legal-entity-consumer.sh")
  set(version: current_version(:deactivate_legal_entity_consumer))

  set(
    applications: [
      deactivate_legal_entity_consumer: :permanent
    ]
  )
end

release :ehealth_scheduler do
  set(version: current_version(:ehealth_scheduler))

  set(
    applications: [
      ehealth_scheduler: :permanent
    ]
  )
end
