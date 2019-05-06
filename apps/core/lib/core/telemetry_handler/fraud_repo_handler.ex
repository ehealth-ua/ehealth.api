defmodule Core.TelemetryHandler.FraudRepoHandler do
  @moduledoc false

  use EhealthLogger.TelemetryHandler, prefix: :core, repo: :fraud_repo
end
