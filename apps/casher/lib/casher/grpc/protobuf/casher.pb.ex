defmodule CasherProto do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule CasherProto.PersonDataRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_id: String.t(),
          client_id: String.t(),
          employee_id: String.t()
        }
  defstruct [:user_id, :client_id, :employee_id]

  field(:user_id, 1, type: :string)
  field(:client_id, 2, type: :string)
  field(:employee_id, 3, type: :string)
end

defmodule CasherProto.PersonDataResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          person_ids: [String.t()]
        }
  defstruct [:person_ids]

  field(:person_ids, 1, repeated: true, type: :string)
end

defmodule CasherGrpc.Service do
  @moduledoc false
  use GRPC.Service, name: "CasherGrpc"

  rpc(:PersonData, CasherProto.PersonDataRequest, CasherProto.PersonDataResponse)
end

defmodule CasherGrpc.Stub do
  @moduledoc false
  use GRPC.Stub, service: CasherGrpc.Service
end
