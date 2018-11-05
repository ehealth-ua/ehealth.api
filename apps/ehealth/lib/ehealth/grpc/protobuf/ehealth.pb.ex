defmodule EHealthProto do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule EHealthProto.PartyUserRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_id: String.t()
        }
  defstruct [:user_id]

  field(:user_id, 1, type: :string)
end

defmodule EHealthProto.PartyUserResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          party_user: EHealthProto.PartyUserResponse.PartyUser.t()
        }
  defstruct [:party_user]

  field(:party_user, 1, type: EHealthProto.PartyUserResponse.PartyUser)
end

defmodule EHealthProto.PartyUserResponse.PartyUser do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          party_id: String.t()
        }
  defstruct [:party_id]

  field(:party_id, 1, type: :string)
end

defmodule EHealthProto.EmployeesRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          party_id: String.t(),
          legal_entity_id: String.t()
        }
  defstruct [:party_id, :legal_entity_id]

  field(:party_id, 1, type: :string)
  field(:legal_entity_id, 2, type: :string)
end

defmodule EHealthProto.EmployeesResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          employees: [EHealthProto.EmployeesResponse.Employee.t()]
        }
  defstruct [:employees]

  field(:employees, 1, repeated: true, type: EHealthProto.EmployeesResponse.Employee)
end

defmodule EHealthProto.EmployeesResponse.Employee do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          speciality: EHealthProto.EmployeesResponse.Speciality.t()
        }
  defstruct [:speciality]

  field(:speciality, 1, type: EHealthProto.EmployeesResponse.Speciality)
end

defmodule EHealthProto.EmployeesResponse.Speciality do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          speciality: String.t()
        }
  defstruct [:speciality]

  field(:speciality, 1, type: :string)
end

defmodule EHealthGrpc.Service do
  @moduledoc false
  use GRPC.Service, name: "EHealthGrpc"

  rpc(:PartyUser, EHealthProto.PartyUserRequest, EHealthProto.PartyUserResponse)
  rpc(:EmployeesSpeciality, EHealthProto.EmployeesRequest, EHealthProto.EmployeesResponse)
end

defmodule EHealthGrpc.Stub do
  @moduledoc false
  use GRPC.Stub, service: EHealthGrpc.Service
end
