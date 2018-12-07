defmodule Core.OPSFactories.MedicationRequestFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def medication_request_factory do
        %{
          id: UUID.generate(),
          status: "ACTIVE",
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          is_active: true,
          person_id: UUID.generate(),
          employee_id: UUID.generate(),
          division_id: UUID.generate(),
          medication_id: UUID.generate(),
          created_at: NaiveDateTime.utc_now() |> NaiveDateTime.to_date(),
          started_at: NaiveDateTime.utc_now() |> NaiveDateTime.to_date(),
          ended_at: NaiveDateTime.utc_now() |> NaiveDateTime.to_date(),
          dispense_valid_from: Date.utc_today(),
          dispense_valid_to: Date.utc_today(),
          medical_program_id: UUID.generate(),
          medication_qty: 0,
          medication_request_requests_id: UUID.generate(),
          request_number: to_string(:rand.uniform()),
          legal_entity_id: UUID.generate(),
          inserted_at: NaiveDateTime.utc_now(),
          updated_at: NaiveDateTime.utc_now(),
          verification_code: "",
          rejected_at: nil,
          rejected_by: nil,
          reject_reason: nil,
          intent: "order",
          category: "community",
          context: build(:medical_events_context),
          dosage_instruction: medical_events_dosage_instruction()
        }
      end

      def medical_events_context_factory do
        %{
          identifier: %{
            type: %{
              coding: [
                %{
                  system: "eHealth/resources",
                  code: "encounter"
                }
              ]
            },
            value: UUID.generate()
          }
        }
      end

      defp medical_events_dosage_instruction do
        [
          %{
            "sequence" => 1,
            "text" =>
              "0.25mg PO every 6-12 hours as needed for menses from Jan 15-20, 2015.  Do not exceed more than 4mg per day",
            "additional_instruction" => [
              %{
                "coding" => [
                  %{
                    "system" => "eHealth/SNOMED/additional_dosage_instructions",
                    "code" => "311504000"
                  }
                ]
              }
            ],
            "patient_instruction" =>
              "0.25mg PO every 6-12 hours as needed for menses from Jan 15-20, 2015.  Do not exceed more than 4mg per day",
            "timing" => %{
              "event" => [
                "2017-04-20T19:14:13Z"
              ],
              "repeat" => %{
                "bounds_duration" => %{
                  "value" => 10,
                  "unit" => "days",
                  "system" => "http://unitsofmeasure.org",
                  "code" => "d"
                },
                "count" => 2,
                "count_max" => 4,
                "duration" => 4,
                "duration_max" => 6,
                "duration_unit" => "d",
                "frequency" => 1,
                "frequency_max" => 2,
                "period" => 4,
                "period_max" => 6,
                "period_unit" => "d",
                "day_of_week" => [
                  "mon"
                ],
                "time_of_day" => [
                  "2017-04-20T19:14:13Z"
                ],
                "when" => [
                  "WAKE"
                ],
                "offset" => 4
              },
              "code" => %{
                "coding" => [
                  %{
                    "system" => "eHealth/timing_abbreviation",
                    "code" => "patient"
                  }
                ]
              }
            },
            "as_needed_boolean" => true,
            "site" => %{
              "coding" => [
                %{
                  "system" => "eHealth/SNOMED/anatomical_structure_administration_site_codes",
                  "code" => "344001"
                }
              ]
            },
            "route" => %{
              "coding" => [
                %{
                  "system" => "eHealth/SNOMED/route_codes",
                  "code" => "46713006"
                }
              ]
            },
            "method" => %{
              "coding" => [
                %{
                  "system" => "eHealth/SNOMED/administration_methods",
                  "code" => "419747000"
                }
              ]
            },
            "dose_and_rate" => %{
              "type" => %{
                "coding" => [
                  %{
                    "system" => "eHealth/dose_and_rate",
                    "code" => "'ordered'"
                  }
                ]
              },
              "dose_range" => %{
                "low" => %{
                  "value" => 13,
                  "comparator" => ">",
                  "unit" => "mg",
                  "system" => "eHealth/units",
                  "code" => "mg"
                },
                "high" => %{
                  "value" => 13,
                  "comparator" => ">",
                  "unit" => "mg",
                  "system" => "eHealth/units",
                  "code" => "mg"
                }
              },
              "rate_ratio" => %{
                "numerator" => %{
                  "value" => 13,
                  "comparator" => ">",
                  "unit" => "mg",
                  "system" => "eHealth/units",
                  "code" => "mg"
                },
                "denominator" => %{
                  "value" => 13,
                  "comparator" => ">",
                  "unit" => "mg",
                  "system" => "eHealth/units",
                  "code" => "mg"
                }
              }
            },
            "max_dose_per_period" => %{
              "numerator" => %{
                "value" => 13,
                "comparator" => ">",
                "unit" => "mg",
                "system" => "eHealth/units",
                "code" => "mg"
              },
              "denominator" => %{
                "value" => 13,
                "comparator" => ">",
                "unit" => "mg",
                "system" => "eHealth/units",
                "code" => "mg"
              }
            },
            "max_dose_per_administration" => %{
              "value" => 13,
              "unit" => "mg",
              "system" => "eHealth/units",
              "code" => "mg"
            },
            "max_dose_per_lifetime" => %{
              "value" => 13,
              "unit" => "mg",
              "system" => "eHealth/units",
              "code" => "mg"
            }
          }
        ]
      end
    end
  end
end
