defmodule Core.PRMRepo.Migrations.UpdateProgramMedicationsAdditionalFields do
  use Ecto.Migration

  def change do
    execute("""
        UPDATE program_medications
        SET wholesale_price = 25.14,
            consumer_price = 34.03,
            reimbursement_daily_dosage = 1.4438,
            estimated_payment_amount = 5.15
        WHERE id = '94456d00-6088-4189-963b-c2dc60453f00';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 36.35,
            consumer_price = 49.20,
            reimbursement_daily_dosage = 1.4438,
            estimated_payment_amount = 5.89
        WHERE id = 'd3bc81db-7e8e-49db-a6b9-7c836bf6cdb7';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 32.00,
            consumer_price = 43.31,
            reimbursement_daily_dosage = 1.4438,
            estimated_payment_amount = 0.00
        WHERE id = '62415d21-7996-422f-b023-9832131c0bbd';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 45.00,
            consumer_price = 60.91,
            reimbursement_daily_dosage = 1.4438,
            estimated_payment_amount = 17.60
        WHERE id = 'b0d0fe78-0066-430d-b63f-fc406412db08';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 63.83,
            consumer_price = 86.40,
            reimbursement_daily_dosage = 1.4438,
            estimated_payment_amount = 43.09
        WHERE id = '008e7cfd-f5a2-4c78-a4fd-83c7f3af803b';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 35.00,
            consumer_price = 47.37,
            reimbursement_daily_dosage = 1.4438,
            estimated_payment_amount = 4.06
        WHERE id = 'cb267bcf-8082-4520-872a-0a41a9090e02';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 45.00,
            consumer_price = 60.91,
            reimbursement_daily_dosage = 1.4438,
            estimated_payment_amount = 17.60
        WHERE id = 'b0673475-aaf1-480c-8140-b2aed6edf4c7';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 65.25,
            consumer_price = 88.32,
            reimbursement_daily_dosage = 1.4438,
            estimated_payment_amount = 45.01
        WHERE id = '23dc19d6-82a5-4eaa-b69a-d5a0e532af76';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 59.60,
            consumer_price = 80.67,
            reimbursement_daily_dosage = 1.4438,
            estimated_payment_amount = 8.48
        WHERE id = '3388cdc1-9157-4adf-8d43-ea677a00de28';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 127.65,
            consumer_price = 172.78,
            reimbursement_daily_dosage = 1.4438,
            estimated_payment_amount = 86.15
        WHERE id = 'ce62ff52-d784-4b6b-bc52-cf0389390c1b';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.00,
            consumer_price = 8.12,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = '52a7fd36-823b-461d-a485-1add8ef916b8';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 12.00,
            consumer_price = 16.24,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = 'd1d4a07f-a8de-448d-8334-6c348170ba1a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.37,
            consumer_price = 8.62,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.50
        WHERE id = 'f83d3cb8-f856-46f6-bde6-93b197342c5a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.37,
            consumer_price = 8.62,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.50
        WHERE id = 'b664cd8c-2272-4e50-a09c-e12195217899';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 18.00,
            consumer_price = 24.36,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = '844c3eed-f56c-423c-ab5f-400a716d6c6d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 10.74,
            consumer_price = 14.54,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 1.00
        WHERE id = '0176e75b-20ae-436b-9607-62f2eb8ac314';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 10.74,
            consumer_price = 14.54,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 1.00
        WHERE id = 'a36ff5fd-ab21-4832-81f6-8c7ed0ce2b2d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 4.82,
            consumer_price = 6.52,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 1.11
        WHERE id = 'fb13e05b-b9cf-43f8-839f-eb1558c71e98';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 7.68,
            consumer_price = 10.40,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 4.99
        WHERE id = '05ec2661-90f0-48d2-ac01-416e7a4c0c94';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.75,
            consumer_price = 13.20,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 5.08
        WHERE id = '50768b85-cf39-4da3-b28b-03fb7d717dda';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.75,
            consumer_price = 13.20,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 5.08
        WHERE id = '7d45747f-7a9b-4220-83a6-eb88021c7fc7';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 10.24,
            consumer_price = 13.86,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 5.74
        WHERE id = 'a6accf3a-3677-4e64-95df-80a46529ffab';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 8.56,
            consumer_price = 11.59,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 6.18
        WHERE id = 'e28d17d3-3370-4743-8c81-4cdf77ff2e80';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 14.70,
            consumer_price = 19.90,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 11.78
        WHERE id = 'c338b085-cd3b-4b0b-a025-0a80101f7a8c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 16.44,
            consumer_price = 22.25,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 14.13
        WHERE id = 'd7b9bd87-873e-4ce4-aa94-31b16e91a1bf';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 22.99,
            consumer_price = 31.12,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 23.00
        WHERE id = '76bccab2-54c7-41b8-a72a-6e5a0f4af2e4';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 24.99,
            consumer_price = 33.83,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 25.71
        WHERE id = '918b542a-fb5b-41f1-ac45-0288c7b12620';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 25.67,
            consumer_price = 34.75,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 26.63
        WHERE id = '6cf9c3d8-4518-40d4-8ad6-cc36e187c3c7';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 25.69,
            consumer_price = 34.77,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 26.65
        WHERE id = 'a7172ea4-3d99-43d9-bd34-6dae382760ff';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 12.00,
            consumer_price = 16.24,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = '47c6eb5f-c560-48f4-b862-4dc01bc3d2ab';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 20.00,
            consumer_price = 27.07,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = 'a5318c68-453c-45ad-a172-cf553d96a43f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 12.00,
            consumer_price = 16.24,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = '13b46fe8-afea-4332-a0e0-644558f052df';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 20.00,
            consumer_price = 27.07,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = '5c3cd41f-f21b-4430-95da-e8e8232c5d5c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 12.00,
            consumer_price = 16.24,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = 'c2f345d6-af7b-4209-b8b4-6c2b2d1b7a0e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 24.00,
            consumer_price = 32.49,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = 'ef1e311c-da2f-42bb-91a5-15335a2a008a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 8.00,
            consumer_price = 10.83,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = 'ff6a5f6b-8eb8-4973-a003-e308a6bf2f18';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 8.96,
            consumer_price = 12.13,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 1.30
        WHERE id = '26e12952-a7a0-4523-bf7f-5c767d46f840';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 36.00,
            consumer_price = 48.73,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 0.00
        WHERE id = '74922536-0785-4d7d-a374-368ee022c04d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 13.60,
            consumer_price = 18.41,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 2.17
        WHERE id = 'b3d8fcdb-1368-4ec7-b5a7-9a2d183d1df4';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.93,
            consumer_price = 13.44,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 2.61
        WHERE id = '90deee85-ae07-4f8a-8ff0-7e54a19dce1e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 15.00,
            consumer_price = 20.30,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 4.06
        WHERE id = '3c57c070-df31-4c83-aa9d-c13a4384016e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 15.00,
            consumer_price = 20.30,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 4.06
        WHERE id = '7f4f8441-53d7-46d4-9a1b-7731048d774e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 22.90,
            consumer_price = 31.00,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 14.76
        WHERE id = 'c479d356-ced2-4266-ace8-22f5d3b262cc';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 41.97,
            consumer_price = 56.81,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 40.57
        WHERE id = '9b5fbb23-62a3-44c2-836b-cdcdf31effcf';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 45.06,
            consumer_price = 60.99,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 44.75
        WHERE id = 'e5045af8-508f-4177-b9a9-e9c0ebfd739e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 51.34,
            consumer_price = 69.49,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 53.25
        WHERE id = 'e20738c1-9216-41fa-b54c-58c82cbfa95a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 51.38,
            consumer_price = 69.55,
            reimbursement_daily_dosage = 0.2707,
            estimated_payment_amount = 53.31
        WHERE id = '8d2f5cb5-0264-4741-a078-e47eafbc331d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.60,
            consumer_price = 12.99,
            reimbursement_daily_dosage = 0.4873,
            estimated_payment_amount = 0.00
        WHERE id = '82fcdf21-9812-41bf-980c-169289907a5f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.72,
            consumer_price = 9.10,
            reimbursement_daily_dosage = 0.4873,
            estimated_payment_amount = 2.60
        WHERE id = '6ef8d2b5-66de-4fbe-b2d7-849adc918849';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 7.44,
            consumer_price = 10.07,
            reimbursement_daily_dosage = 0.4873,
            estimated_payment_amount = 3.57
        WHERE id = '34a211b0-2e3f-4160-a4f9-4255433fb94f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.00,
            consumer_price = 8.12,
            reimbursement_daily_dosage = 0.4873,
            estimated_payment_amount = 1.62
        WHERE id = 'd7b78128-8790-4124-8965-f0aa5c1cb636';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.65,
            consumer_price = 13.06,
            reimbursement_daily_dosage = 1.8273,
            estimated_payment_amount = 6.97
        WHERE id = '13d3c005-5324-44aa-9fac-34a47cdf4388';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 4.50,
            consumer_price = 6.09,
            reimbursement_daily_dosage = 1.8273,
            estimated_payment_amount = 0.00
        WHERE id = '39246fe3-a3ae-4b95-9b4e-f08cf53a6f54';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 22.50,
            consumer_price = 30.45,
            reimbursement_daily_dosage = 1.8273,
            estimated_payment_amount = 0.00
        WHERE id = '3c66b2e4-8d81-4363-92c1-a8a4a75c6721';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 22.50,
            consumer_price = 30.45,
            reimbursement_daily_dosage = 1.8273,
            estimated_payment_amount = 0.00
        WHERE id = 'c766ef7f-05ae-4b73-b435-ecda4b921473';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 17.50,
            consumer_price = 23.69,
            reimbursement_daily_dosage = 1.1844,
            estimated_payment_amount = 0.00
        WHERE id = '244352bb-d439-45fa-b481-960b1f6c8344';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 28.28,
            consumer_price = 38.28,
            reimbursement_daily_dosage = 2.8208,
            estimated_payment_amount = 19.47
        WHERE id = '661712b9-c0b2-4501-80bf-c451ccead7d1';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 20.84,
            consumer_price = 28.21,
            reimbursement_daily_dosage = 2.8208,
            estimated_payment_amount = 0.00
        WHERE id = 'c150572b-439e-496e-8a17-4a303ff9347e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 53.74,
            consumer_price = 72.74,
            reimbursement_daily_dosage = 2.8208,
            estimated_payment_amount = 16.32
        WHERE id = '891e665e-702f-4fb0-9134-d3489ff849b9';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 83.36,
            consumer_price = 112.83,
            reimbursement_daily_dosage = 2.8208,
            estimated_payment_amount = 0.00
        WHERE id = '95a64152-d69c-488f-9818-83c0ee941870';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 83.36,
            consumer_price = 112.83,
            reimbursement_daily_dosage = 2.8208,
            estimated_payment_amount = 0.00
        WHERE id = 'e91d4ae6-18c2-4ade-96a4-1fb59fe15135';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.35,
            consumer_price = 8.60,
            reimbursement_daily_dosage = 0.1719,
            estimated_payment_amount = 0.00
        WHERE id = '73e5591c-51d8-4020-9af2-136cd3aca0f5';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.35,
            consumer_price = 8.60,
            reimbursement_daily_dosage = 0.1719,
            estimated_payment_amount = 0.00
        WHERE id = 'a55467d5-f8a4-4595-ab11-6be2ed892590';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.35,
            consumer_price = 8.60,
            reimbursement_daily_dosage = 0.1719,
            estimated_payment_amount = 0.00
        WHERE id = 'cd7bba88-36c4-4c3c-912d-16fca0a54697';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 10.49,
            consumer_price = 14.20,
            reimbursement_daily_dosage = 0.1719,
            estimated_payment_amount = 5.60
        WHERE id = 'd9b372c9-f648-4496-8d9e-7104bf25b311';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.10,
            consumer_price = 8.26,
            reimbursement_daily_dosage = 0.2064,
            estimated_payment_amount = 0.00
        WHERE id = 'b309edf3-16ed-42a7-bcd5-e3c7fb1dec79';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 7.63,
            consumer_price = 10.32,
            reimbursement_daily_dosage = 0.2064,
            estimated_payment_amount = 0.00
        WHERE id = '4e10b5dc-5f76-4d31-a8ae-16ba1f1ab8ce';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.51,
            consumer_price = 8.81,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 6.43
        WHERE id = '6003c070-91e2-4931-9c74-4a083ac41a27';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 8.98,
            consumer_price = 12.15,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 8.58
        WHERE id = 'ef7ad6d2-39c8-4e32-91c1-9cacf34046fc';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 18.68,
            consumer_price = 25.28,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 21.71
        WHERE id = 'cd35e965-50a7-4388-957e-dece83bc475a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 3.52,
            consumer_price = 4.76,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 0.00
        WHERE id = '1c941199-ee94-471f-a65f-4c580c19c2ec';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 8.40,
            consumer_price = 11.37,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 6.61
        WHERE id = '02180c3f-4120-413a-bfbd-0b4da0c0644d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 8.22,
            consumer_price = 11.13,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 6.37
        WHERE id = 'd1e93316-36ae-4304-af03-4bdc1f04412a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.50,
            consumer_price = 8.80,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 4.04
        WHERE id = '7b6bd18f-e955-4c3a-83ce-f1fd9268deb5';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 8.80,
            consumer_price = 11.91,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 0.00
        WHERE id = '9dd9b8c0-030f-41e3-8aa9-0b53987e1d62';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 15.84,
            consumer_price = 21.44,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 0.00
        WHERE id = '7e1fddfe-d339-4eb1-b3d4-65cdeb10e2ff';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 5.12,
            consumer_price = 6.93,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 2.17
        WHERE id = '1407b646-11d4-4db5-a7db-d639499abbc4';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 3.52,
            consumer_price = 4.76,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 0.00
        WHERE id = '1235086a-4142-4fb9-8e9c-db02cbdb86f8';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 7.00,
            consumer_price = 9.47,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 4.71
        WHERE id = '3955cee6-0b5c-47cb-b679-9a044576e2e2';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 29.70,
            consumer_price = 40.20,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 33.05
        WHERE id = 'a1d0b137-ed17-4362-ba5a-0a881d8c8d59';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 10.50,
            consumer_price = 14.21,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 9.45
        WHERE id = 'fffe102f-432a-4239-9d3c-168574871653';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 24.96,
            consumer_price = 33.78,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 29.02
        WHERE id = '174df00b-0aa9-4cfe-9b47-37dd3575d25f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 10.89,
            consumer_price = 14.74,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 5.21
        WHERE id = '046800af-4963-4dd9-94e6-6de68a5605b0';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 8.00,
            consumer_price = 10.83,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 1.30
        WHERE id = '8338a0c9-cb40-47c0-a754-7e25ccb717cf';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 10.21,
            consumer_price = 13.82,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 4.29
        WHERE id = '60a8ae4f-cf10-46f6-b394-14429c2c922e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 43.48,
            consumer_price = 58.85,
            reimbursement_daily_dosage = 0.2382,
            estimated_payment_amount = 44.56
        WHERE id = '57bd9bc2-9045-4790-96b6-af8abd404d02';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 13.22,
            consumer_price = 17.89,
            reimbursement_daily_dosage = 4.2945,
            estimated_payment_amount = 0.00
        WHERE id = 'ebaf9dd6-bac5-435f-a2a6-13d8fc1b7057';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.99,
            consumer_price = 13.52,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 1.34
        WHERE id = '7a63b4c9-771d-4719-ad9d-c9604c3cdbfe';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 17.90,
            consumer_price = 24.23,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 16.11
        WHERE id = '53c4053b-2491-43bb-b75f-4d9361287bca';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 19.20,
            consumer_price = 25.99,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 13.81
        WHERE id = '5fd4553d-944f-42fc-8505-577901341778';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 24.29,
            consumer_price = 32.88,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 21.51
        WHERE id = '4505e55d-5465-44bf-b566-a642e99b8292';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 19.98,
            consumer_price = 27.04,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 2.68
        WHERE id = '59e6d24d-722a-4dec-bc73-c93122662228';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 24.00,
            consumer_price = 32.49,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 8.13
        WHERE id = '8b671d33-ccd4-424e-b14c-a8253d3ee5d6';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 35.90,
            consumer_price = 48.59,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 32.35
        WHERE id = 'd2ba3b3c-2848-486c-ba4e-99c3006dcab2';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 32.00,
            consumer_price = 43.31,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 18.95
        WHERE id = 'abc60f7d-d4e7-4bea-93a9-cd4ae09b1bef';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 47.33,
            consumer_price = 64.06,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 39.70
        WHERE id = '6552cc5e-0253-47a5-bec5-eb7c5983e30d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 43.76,
            consumer_price = 59.23,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 36.49
        WHERE id = '8a0ecb54-8ce3-4506-a18f-7bd13f43067f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 39.96,
            consumer_price = 54.09,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 5.36
        WHERE id = '65960e13-5837-4c82-8a3e-e73ac755cba9';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 36.00,
            consumer_price = 48.73,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 0.00
        WHERE id = '361aafda-ebf6-410b-ab65-208c9142db20';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 71.79,
            consumer_price = 97.17,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 64.68
        WHERE id = 'a7e4fd67-a5e1-49b2-98de-d58c9cb45df1';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 49.92,
            consumer_price = 67.57,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 18.84
        WHERE id = '63a12acb-64f7-4521-9f3f-e0a2ac5f7c62';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 81.18,
            consumer_price = 109.88,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 61.15
        WHERE id = 'a34369ca-bac6-4943-b018-9a7f37bc030e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 58.22,
            consumer_price = 78.80,
            reimbursement_daily_dosage = 2.4364,
            estimated_payment_amount = 33.32
        WHERE id = 'b49a8fd9-74b0-44f8-8c2c-43bec7177658';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 16.75,
            consumer_price = 22.67,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 6.66
        WHERE id = '3e4dff55-9da1-451f-9441-7747c87da2d5';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 19.00,
            consumer_price = 25.72,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 9.71
        WHERE id = 'ea88dc77-f87f-4ee0-a4cd-9de6020facdf';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 81.20,
            consumer_price = 109.91,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 65.09
        WHERE id = '4a062204-ca21-4487-ac85-5206d6a78ee8';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 53.90,
            consumer_price = 72.96,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 28.14
        WHERE id = 'd6d32925-be73-4e34-8127-db91dfb6f4f3';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 52.37,
            consumer_price = 70.89,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 22.87
        WHERE id = 'd16f8097-2ea0-47bb-8d7f-41ce58a56168';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 57.60,
            consumer_price = 77.96,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 29.94
        WHERE id = 'b28bf998-153b-4565-b870-29b507430b72';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 62.70,
            consumer_price = 84.87,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 36.85
        WHERE id = '9633a4b3-8bfb-4b38-b6c4-596fc7c92a2c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 62.70,
            consumer_price = 84.87,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 36.85
        WHERE id = 'a620e749-d83b-49fc-adb9-911e9abcc4a7';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 64.50,
            consumer_price = 87.30,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 39.28
        WHERE id = '375123b2-1da7-43ae-a619-0723a69193a5';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 43.93,
            consumer_price = 59.46,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 11.44
        WHERE id = 'f4b530d1-f8e6-441c-8779-0601171424d9';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 43.93,
            consumer_price = 59.46,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 11.44
        WHERE id = 'a545666c-b222-4a7b-bd4c-e3ad688d1beb';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 35.48,
            consumer_price = 48.02,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 0.00
        WHERE id = '59f8f6da-74fa-494a-923c-9d3fe2ba5756';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 86.98,
            consumer_price = 117.73,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 69.71
        WHERE id = '136085f2-fea4-4764-bf74-3ea3b6882d0e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 75.00,
            consumer_price = 101.52,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 53.50
        WHERE id = 'c0c9791f-b413-4022-b4f6-b58d0a2a5545';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 50.00,
            consumer_price = 67.68,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 19.66
        WHERE id = '04343d4a-225f-4384-bf78-fa453b299fae';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 40.84,
            consumer_price = 55.28,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 7.26
        WHERE id = '2bd05aa2-33ac-47a0-b277-1e5b945fc9d0';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 61.85,
            consumer_price = 83.72,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 19.69
        WHERE id = '1a8f657a-f980-4958-b1bc-d7068df0162e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 81.69,
            consumer_price = 110.57,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 14.53
        WHERE id = '75fc6445-1423-4020-940a-60775896d6b2';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 81.69,
            consumer_price = 110.57,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 14.53
        WHERE id = '6d4938d7-e7b2-4faa-9309-f1e8778e1d56';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 82.78,
            consumer_price = 112.05,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 0.00
        WHERE id = '5a6ad159-63bd-45e0-825a-b4f583946ee2';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 114.35,
            consumer_price = 154.78,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 20.33
        WHERE id = '5678c9a4-b250-4676-9880-e0447c1d36b3';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 171.00,
            consumer_price = 231.46,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 87.40
        WHERE id = '5f6c39b5-6122-4909-bd4e-117830e3eeb2';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 171.00,
            consumer_price = 231.46,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 87.40
        WHERE id = 'da868893-b68f-44b2-817b-dd5c90b9b81f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 177.30,
            consumer_price = 239.98,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 95.92
        WHERE id = '4c68f125-3958-4c61-90a2-00ef00b211fc';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 106.43,
            consumer_price = 144.06,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 0.00
        WHERE id = '365b6c8b-8f47-4958-8f27-eff8f2b1608d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 136.14,
            consumer_price = 184.27,
            reimbursement_daily_dosage = 1.6006,
            estimated_payment_amount = 24.21
        WHERE id = '7da6e7c0-5330-4215-bafa-ee78f8f66692';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 27.85,
            consumer_price = 37.70,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 24.16
        WHERE id = '974d99a0-0ebb-480f-b7bd-74a2d1428e64';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 42.90,
            consumer_price = 58.07,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 32.80
        WHERE id = '9c6d3e1d-c67e-49cd-9508-6a482ecbca82';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 73.00,
            consumer_price = 98.81,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 23.01
        WHERE id = 'ec7da78e-48ab-4de0-9fac-661dc3529e92';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 154.85,
            consumer_price = 209.60,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 128.39
        WHERE id = '93b06bc4-aed7-4921-bd50-ae6d44b47079';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 48.99,
            consumer_price = 66.31,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 39.24
        WHERE id = '8075f7ae-72fc-496f-af0a-425423975043';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 77.32,
            consumer_price = 104.66,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 23.45
        WHERE id = '2b81c835-a9f3-4716-90e7-7c946fcbd0a5';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 22.30,
            consumer_price = 30.18,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 3.11
        WHERE id = '8ab4b0ae-2379-443a-b49b-eb7021d0f09f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 56.73,
            consumer_price = 76.79,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 49.72
        WHERE id = '55602ec8-404e-429d-9954-dc6938a57231';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 20.00,
            consumer_price = 27.07,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 0.00
        WHERE id = 'd2d6fd34-764d-4fcd-8d40-b02c4eef1815';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 148.69,
            consumer_price = 201.26,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 20.79
        WHERE id = 'c333a795-4914-4cd2-b1f4-ae9154a7a673';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 58.00,
            consumer_price = 78.51,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 24.37
        WHERE id = 'e7396a91-4b99-4181-a5ee-0605b804b4ce';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 213.69,
            consumer_price = 289.24,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 126.81
        WHERE id = '2cbe5023-313f-4a64-abf8-543bae4bf872';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 96.23,
            consumer_price = 130.25,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 76.11
        WHERE id = 'f10cabf9-56ae-4c65-9306-696d2f40f807';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 56.64,
            consumer_price = 76.67,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 22.53
        WHERE id = '0c64c055-0106-49a4-b1a9-4635cfddef2d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 44.60,
            consumer_price = 60.37,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 6.23
        WHERE id = '56f8640b-3aef-4ee7-b902-3e1c984d5a64';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 113.46,
            consumer_price = 153.57,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 99.43
        WHERE id = 'b1a02346-600e-4bd2-9ae2-fa80e31b8a56';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 40.00,
            consumer_price = 54.14,
            reimbursement_daily_dosage = 0.9024,
            estimated_payment_amount = 0.00
        WHERE id = 'eb267a46-d96a-4f64-b1eb-794cdc3f525f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 23.13,
            consumer_price = 31.31,
            reimbursement_daily_dosage = 1.1059,
            estimated_payment_amount = 20.25
        WHERE id = 'fcfd7b72-3ed2-416c-b808-aa6ad79ffecd';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 46.07,
            consumer_price = 62.36,
            reimbursement_daily_dosage = 1.1059,
            estimated_payment_amount = 40.24
        WHERE id = '3ef47f4c-6965-4202-a948-043b23321cec';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.31,
            consumer_price = 12.60,
            reimbursement_daily_dosage = 1.1059,
            estimated_payment_amount = 1.54
        WHERE id = '293fa84b-d5eb-4f36-afb8-acc38770938c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.50,
            consumer_price = 12.86,
            reimbursement_daily_dosage = 1.1059,
            estimated_payment_amount = 5.49
        WHERE id = '5551ae31-567e-4d29-8f21-9abcdbe5a4f9';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 46.07,
            consumer_price = 62.36,
            reimbursement_daily_dosage = 1.1059,
            estimated_payment_amount = 40.24
        WHERE id = 'e5c34294-62d7-4acf-a87b-ea6035b643bc';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 81.55,
            consumer_price = 110.38,
            reimbursement_daily_dosage = 1.1059,
            estimated_payment_amount = 66.15
        WHERE id = '77b32207-0156-4a78-99ed-8f700c519543';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 16.34,
            consumer_price = 22.12,
            reimbursement_daily_dosage = 1.1059,
            estimated_payment_amount = 0.00
        WHERE id = 'e6a87ff8-b859-4cb5-af45-94957da9abda';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 14.50,
            consumer_price = 19.63,
            reimbursement_daily_dosage = 1.1059,
            estimated_payment_amount = 4.89
        WHERE id = '557c942b-3a55-4678-b50c-33a75cf44fa3';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.30,
            consumer_price = 8.53,
            reimbursement_daily_dosage = 1.0659,
            estimated_payment_amount = 0.00
        WHERE id = '3bb886e3-6652-4219-a012-e973dc4b04e5';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 6.30,
            consumer_price = 8.53,
            reimbursement_daily_dosage = 1.0659,
            estimated_payment_amount = 0.00
        WHERE id = '4844b50e-4409-4619-89ac-567c0eea2fd3';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 7.00,
            consumer_price = 9.47,
            reimbursement_daily_dosage = 1.0659,
            estimated_payment_amount = 0.94
        WHERE id = 'b20b736b-6211-4952-b7b3-0d8552d1f4ec';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 24.82,
            consumer_price = 33.60,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 10.59
        WHERE id = '2771e507-c8cc-4f4e-9ce6-aae07af37769';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 18.00,
            consumer_price = 24.36,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 1.35
        WHERE id = 'b3cb8765-eef3-4903-8483-3947e90ede75';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 34.00,
            consumer_price = 46.02,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 0.00
        WHERE id = '970d860c-2815-42bc-909f-1d700a8e5808';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 40.44,
            consumer_price = 54.74,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 11.79
        WHERE id = '57f0a214-43d5-4213-93f4-0b05966f5e8e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 45.90,
            consumer_price = 62.13,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 16.11
        WHERE id = 'b4879407-f086-4188-ae4e-62589a7835cc';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 36.00,
            consumer_price = 48.73,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 2.71
        WHERE id = 'df1e5e4e-1288-4db4-903e-01f3b7bb4112';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 35.65,
            consumer_price = 48.25,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 5.30
        WHERE id = 'be0a4e02-3c79-4f09-ac20-1e00c7c6a0c3';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 68.00,
            consumer_price = 92.04,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 0.00
        WHERE id = '2fb34860-fec8-45a3-a321-3c01a762f126';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 80.89,
            consumer_price = 109.49,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 23.58
        WHERE id = '74c7c675-1581-4295-99c0-1b6913c0136c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 242.67,
            consumer_price = 328.47,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 70.75
        WHERE id = '0f70ded1-107e-4402-92d1-f552d00ae37d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 85.68,
            consumer_price = 115.97,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 23.93
        WHERE id = 'bb96573d-91c9-4732-9913-e0f0e6aba5bb';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 72.00,
            consumer_price = 97.46,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 5.42
        WHERE id = '030508ec-fb7a-41ba-8a61-8728b91d97f7';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 71.29,
            consumer_price = 96.49,
            reimbursement_daily_dosage = 2.3010,
            estimated_payment_amount = 10.58
        WHERE id = '61b3d9fc-acc3-43ca-b3cf-4af7aaa6ce02';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 4.20,
            consumer_price = 5.68,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 0.41
        WHERE id = '38d138c3-af5c-4c41-bb4d-329fd6564640';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 4.88,
            consumer_price = 6.61,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 0.96
        WHERE id = '394ff6c1-0837-4622-b23b-a967af4a296c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 13.92,
            consumer_price = 18.84,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 0.00
        WHERE id = '15b0eba0-380c-4b33-af1e-33fa3643de96';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 8.41,
            consumer_price = 11.38,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 0.83
        WHERE id = '83bcd4b2-8078-4860-9029-423fd7c75097';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.45,
            consumer_price = 12.79,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 1.49
        WHERE id = 'b78d1ba6-8543-4ba6-a26c-5793f743d889';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.70,
            consumer_price = 13.13,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 1.83
        WHERE id = '3f8a5c84-4984-4bd7-86e8-b13b1778f69c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 9.75,
            consumer_price = 13.20,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 1.90
        WHERE id = '1c847b6b-886a-46ca-9fa5-cdaf3d17805c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 10.50,
            consumer_price = 14.21,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 2.91
        WHERE id = '211dbcbe-7208-48e4-af95-baf6689f7ce3';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 11.20,
            consumer_price = 15.16,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 3.86
        WHERE id = '212b6bff-7b1a-4a95-bca3-367b77a0fda5';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 8.88,
            consumer_price = 12.02,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 4.49
        WHERE id = 'd9641f57-b1e4-4a53-81e3-523558f8df0f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 10.00,
            consumer_price = 13.54,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 6.01
        WHERE id = 'd58ae301-0e14-4695-8c46-8c0207cd5c9b';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 19.78,
            consumer_price = 26.77,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 15.47
        WHERE id = '01bf8a5d-b949-4403-97c1-06bc94c3a57c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 25.40,
            consumer_price = 34.38,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 23.08
        WHERE id = 'a7ed62d5-1c8a-4df1-8bfd-47240368b85c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 42.33,
            consumer_price = 57.30,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 38.46
        WHERE id = '844ecfff-699b-4024-a39f-ca0f447166eb';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 57.83,
            consumer_price = 78.28,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 44.37
        WHERE id = '546bac3d-d5a9-4166-9059-6e291d7c363a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 16.70,
            consumer_price = 22.60,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 0.00
        WHERE id = 'd16df548-94d8-4e1a-8ea8-303627719289';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 16.70,
            consumer_price = 22.60,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 0.00
        WHERE id = 'acb4c947-4e09-4249-84e1-86cdda4e7366';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 27.83,
            consumer_price = 37.67,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 0.00
        WHERE id = '99300a6b-af27-4b11-a704-d913108f845a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 16.82,
            consumer_price = 22.77,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 1.67
        WHERE id = '7fe895ce-4b81-4ba8-badb-d3aaf0789cae';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 18.90,
            consumer_price = 25.58,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 2.98
        WHERE id = '96238643-f056-4def-a03e-827c6f7671c0';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 13.44,
            consumer_price = 18.19,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 3.12
        WHERE id = '26328ef9-6765-4818-96ae-d18ca40ad76d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 19.50,
            consumer_price = 26.39,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 3.79
        WHERE id = '8783d6d1-c33a-48f4-8827-31f64f2e5371';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 19.84,
            consumer_price = 26.85,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 4.25
        WHERE id = 'f1d7a7f2-940a-40b3-ade3-e221593ae2f7';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 50.10,
            consumer_price = 67.81,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 0.00
        WHERE id = '45a45b20-5d9c-45d8-9e02-001df18b7525';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 19.00,
            consumer_price = 25.72,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 10.65
        WHERE id = 'ae08e67e-a5df-4ca2-9d60-99dc3276af67';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 32.14,
            consumer_price = 43.50,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 20.90
        WHERE id = '1052d5cf-33d1-4185-88d2-512215c6c5c1';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 33.05,
            consumer_price = 44.73,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 22.13
        WHERE id = '7e091d80-41fc-4308-ba79-01e5dcf96c59';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 55.08,
            consumer_price = 74.55,
            reimbursement_daily_dosage = 0.7535,
            estimated_payment_amount = 36.88
        WHERE id = '8b7b6763-0dd7-428a-8140-9acede897611';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 24.47,
            consumer_price = 33.12,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 0.00
        WHERE id = 'ccc835b5-6958-45f6-9b3a-6d9a34aa075c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 18.00,
            consumer_price = 24.36,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 7.80
        WHERE id = 'd3b079cd-d619-4c13-b62e-232f8f41b73b';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 18.36,
            consumer_price = 24.85,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 8.29
        WHERE id = 'a9134ff7-2b8a-437a-8989-3a9d3c6fd75b';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 40.78,
            consumer_price = 55.20,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 0.00
        WHERE id = 'b5c656f2-5882-4a07-a510-9d28434098b7';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 18.00,
            consumer_price = 24.36,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 7.80
        WHERE id = 'ed304670-8dda-4684-a9a4-c134147c9c54';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 18.00,
            consumer_price = 24.36,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 7.80
        WHERE id = 'fa9069ed-a888-4dcc-9142-af193641142b';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 19.20,
            consumer_price = 25.99,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 9.43
        WHERE id = 'b529ec69-23a4-494f-8606-da9ea5c812bb';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 32.00,
            consumer_price = 43.31,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 10.19
        WHERE id = 'f06b129f-0e04-47e1-8cb3-8c8de6fffba7';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 19.00,
            consumer_price = 25.72,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 9.16
        WHERE id = '41da6aba-82c1-450b-ab0d-7710c023e65a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 35.00,
            consumer_price = 47.37,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 14.25
        WHERE id = 'e1f36a2d-036c-48db-a4f7-7d2e7db5585c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 19.88,
            consumer_price = 26.91,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 10.35
        WHERE id = 'bd8149fa-ebab-46a5-89e6-36739c5b82b8';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 12.24,
            consumer_price = 16.56,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 0.00
        WHERE id = 'ac670443-5de1-44ed-878b-bc938db51729';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 41.39,
            consumer_price = 56.02,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 22.90
        WHERE id = 'eb220d89-a69c-4327-bee5-1f1bd7372968';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 41.60,
            consumer_price = 56.31,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 0.00
        WHERE id = '0378f763-d189-4c51-9ced-127fd60d29bd';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 24.00,
            consumer_price = 32.49,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 4.34
        WHERE id = '3b3a655b-32d6-4094-81a9-1aab68724f32';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 24.48,
            consumer_price = 33.13,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 4.98
        WHERE id = '94715b95-629d-457e-8b1b-a134036dc52d';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 69.33,
            consumer_price = 93.85,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 0.00
        WHERE id = 'e9f3b57b-2f0e-4e22-a439-106cd9f26d6f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 30.00,
            consumer_price = 40.61,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 12.46
        WHERE id = '53db6ba8-958e-4b14-b49d-07a9ccfde2d8';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 30.00,
            consumer_price = 40.61,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 12.46
        WHERE id = '85d9857d-0042-430c-b348-3168dfed41a8';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 41.60,
            consumer_price = 56.31,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 0.00
        WHERE id = '2e93eb08-fc09-4377-843b-b3b096ea4d26';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 22.40,
            consumer_price = 30.32,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 2.17
        WHERE id = 'a1cb2242-1770-44ca-a3b5-8c0d54121558';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 25.50,
            consumer_price = 34.52,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 6.37
        WHERE id = '99a5b21b-7071-4fbf-a664-62a8947ac33e';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 70.37,
            consumer_price = 95.25,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 38.94
        WHERE id = '61e6e2e5-c8b0-4790-87d3-7171e47f77f6';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 20.80,
            consumer_price = 28.15,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 0.00
        WHERE id = 'a7e9534e-e85f-4ed0-8581-15672112ed64';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 77.15,
            consumer_price = 104.43,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 38.19
        WHERE id = '3b26271d-4260-40d7-862b-ec513c564a2a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 77.15,
            consumer_price = 104.43,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 38.19
        WHERE id = '88b9fa53-e213-4a87-a207-fd3cadd3d53b';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 35.00,
            consumer_price = 47.37,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 14.25
        WHERE id = '48f19bc0-4a4a-4f75-bf41-586b913bf2f5';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 92.00,
            consumer_price = 124.53,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 25.16
        WHERE id = 'f4b1737b-2d63-4b1c-b218-b9877319c4c0';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 36.00,
            consumer_price = 48.73,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 15.61
        WHERE id = 'e5957fa3-6a96-4da2-9e02-7fbba61b33e4';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 36.00,
            consumer_price = 48.73,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 15.61
        WHERE id = '53ff26f7-c947-40f0-b545-8d05abf44df0';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 30.40,
            consumer_price = 41.15,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 8.03
        WHERE id = 'b0df0cf4-949c-407b-af10-654c07cc171a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 52.80,
            consumer_price = 71.47,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 5.23
        WHERE id = '29d884cc-adf5-4c49-b637-288b90ff6798';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 27.00,
            consumer_price = 36.55,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 3.43
        WHERE id = '876ac13a-caea-4935-9c2a-9da3e0f9fcdb';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 62.00,
            consumer_price = 83.92,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 17.68
        WHERE id = '01c7d44d-bb60-4c59-940f-9013b20efeb9';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 40.56,
            consumer_price = 54.90,
            reimbursement_daily_dosage = 2.2081,
            estimated_payment_amount = 21.78
        WHERE id = '61d9da21-c90d-4b12-a03d-737e96174e1c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 55.29,
            consumer_price = 74.84,
            reimbursement_daily_dosage = 1.2226,
            estimated_payment_amount = 38.16
        WHERE id = '3b859312-b5f8-4a24-b939-a38fbccf0c4b';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 83.75,
            consumer_price = 113.36,
            reimbursement_daily_dosage = 1.2226,
            estimated_payment_amount = 76.68
        WHERE id = '1e92ed89-1d85-418b-9b1c-ffa3fa7b818a';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 72.26,
            consumer_price = 97.81,
            reimbursement_daily_dosage = 1.2226,
            estimated_payment_amount = 0.00
        WHERE id = '8d555ebb-09a9-4b2c-9631-eb9908944f92';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 38.00,
            consumer_price = 51.43,
            reimbursement_daily_dosage = 1.2226,
            estimated_payment_amount = 33.09
        WHERE id = '3807dc1f-78a0-4509-9ac5-78eebfdfcb53';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 58.00,
            consumer_price = 78.51,
            reimbursement_daily_dosage = 1.2226,
            estimated_payment_amount = 41.83
        WHERE id = '79f042d0-016a-403f-b6d4-31d1a87d20f9';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 65.00,
            consumer_price = 87.98,
            reimbursement_daily_dosage = 1.2226,
            estimated_payment_amount = 51.30
        WHERE id = '12aa8f7e-d242-4f42-a6e5-dbcb91123c3c';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 36.13,
            consumer_price = 48.90,
            reimbursement_daily_dosage = 1.2226,
            estimated_payment_amount = 0.00
        WHERE id = '0b7d755e-8f14-4ebf-83b9-154333c0d919';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 63.87,
            consumer_price = 86.45,
            reimbursement_daily_dosage = 1.2226,
            estimated_payment_amount = 49.77
        WHERE id = '740d7339-1582-4e48-a550-a55a6e9b1882';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 7.50,
            consumer_price = 10.15,
            reimbursement_daily_dosage = 0.6768,
            estimated_payment_amount = 0.00
        WHERE id = '809659e7-b3c9-43bb-9212-db32fc7e20e5';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 12.50,
            consumer_price = 16.92,
            reimbursement_daily_dosage = 0.6768,
            estimated_payment_amount = 0.00
        WHERE id = '4b9d5fbb-8be1-4364-b5dc-9e7c38af7638';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 25.00,
            consumer_price = 33.84,
            reimbursement_daily_dosage = 0.6768,
            estimated_payment_amount = 0.00
        WHERE id = 'f6d16457-a889-4eab-814a-4460cf96a512';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 175.55,
            consumer_price = 237.62,
            reimbursement_daily_dosage = 3.5790,
            estimated_payment_amount = 148.14
        WHERE id = 'cd657e8e-d588-4f5b-a916-dbf2520d7bd6';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 165.26,
            consumer_price = 223.69,
            reimbursement_daily_dosage = 3.5790,
            estimated_payment_amount = 0.00
        WHERE id = '9a15e5a0-49ce-4526-a8cd-fc0200b45fe5';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 663.60,
            consumer_price = 898.22,
            reimbursement_daily_dosage = 67.3662,
            estimated_payment_amount = 0.00
        WHERE id = 'e4fad6e4-a071-4dd9-92d7-ff9f1af0d874';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 120.00,
            consumer_price = 162.43,
            reimbursement_daily_dosage = 5.6083,
            estimated_payment_amount = 92.33
        WHERE id = 'f99f8da8-a74b-4ff8-9093-ccebebf97fc4';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 225.97,
            consumer_price = 305.86,
            reimbursement_daily_dosage = 5.6083,
            estimated_payment_amount = 165.65
        WHERE id = '78616a9d-eeaf-4539-837d-167449f7bc10';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 225.97,
            consumer_price = 305.86,
            reimbursement_daily_dosage = 5.6083,
            estimated_payment_amount = 165.65
        WHERE id = 'e6a6cf8a-d0d7-44ba-871b-0595ccde8627';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 207.17,
            consumer_price = 280.41,
            reimbursement_daily_dosage = 5.6083,
            estimated_payment_amount = 0.00
        WHERE id = 'f0c2e1a5-faf2-47f4-a309-b326a28639bc';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 207.17,
            consumer_price = 280.41,
            reimbursement_daily_dosage = 5.6083,
            estimated_payment_amount = 0.00
        WHERE id = 'c497d95a-be54-452a-9386-8b370b8e651f';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 393.36,
            consumer_price = 532.43,
            reimbursement_daily_dosage = 5.6083,
            estimated_payment_amount = 252.02
        WHERE id = 'c017d95d-badc-4845-88f8-c594e12e22bf';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 56.30,
            consumer_price = 76.20,
            reimbursement_daily_dosage = 2.5988,
            estimated_payment_amount = 11.23
        WHERE id = '71b99d44-7969-4a09-a0be-74a46710abef';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 48.00,
            consumer_price = 64.97,
            reimbursement_daily_dosage = 2.5988,
            estimated_payment_amount = 0.00
        WHERE id = '687d3647-0052-4aa4-9dcf-39122d37f7bd';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 48.00,
            consumer_price = 64.97,
            reimbursement_daily_dosage = 2.5988,
            estimated_payment_amount = 0.00
        WHERE id = 'e7e23a83-b1e2-41ac-b0f0-651df32113d9';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 62.22,
            consumer_price = 84.22,
            reimbursement_daily_dosage = 2.5988,
            estimated_payment_amount = 19.25
        WHERE id = '0a51ff23-3b68-45aa-bec6-d00abb767598';
    """)

    execute("""
        UPDATE program_medications
        SET wholesale_price = 58.21,
            consumer_price = 78.79,
            reimbursement_daily_dosage = 2.5988,
            estimated_payment_amount = 13.82
        WHERE id = '9cdb7c32-f2d4-4fc6-b7d5-30982007ce2d';
    """)
  end
end
