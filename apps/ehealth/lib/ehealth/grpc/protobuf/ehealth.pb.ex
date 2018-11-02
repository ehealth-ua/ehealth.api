defmodule Grpc do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule Grpc.EmployeeRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          id: String.t()
        }
  defstruct [:id]

  field(:id, 1, type: :string)
end

defmodule Grpc.EmployeeResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          employee: Grpc.EmployeeResponse.Employee.t()
        }
  defstruct [:employee]

  field(:employee, 1, type: Grpc.EmployeeResponse.Employee)
end

defmodule Grpc.EmployeeResponse.Employee do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          speciality: Grpc.EmployeeResponse.Speciality.t()
        }
  defstruct [:speciality]

  field(:speciality, 1, type: Grpc.EmployeeResponse.Speciality)
end

defmodule Grpc.EmployeeResponse.Speciality do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          speciality: String.t()
        }
  defstruct [:speciality]

  field(:speciality, 1, type: :string)
end

defmodule Ehealth.Service do
  @moduledoc false
  use GRPC.Service, name: "Ehealth"

  rpc(:EmployeeSpeciality, Grpc.EmployeeRequest, Grpc.EmployeeResponse)
end

defmodule Ehealth.Stub do
  @moduledoc false
  use GRPC.Stub, service: Ehealth.Service
end
