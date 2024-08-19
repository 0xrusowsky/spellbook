 {{
  config(
        schema = 'meteora_v2_solana',
        alias = 'trades',
        materialized = 'view',
        post_hook='{{ expose_spells(\'["solana"]\',
                                    "project",
                                    "meteroa",
                                    \'["ilemi"]\') }}')
}}
select
      *
from
      {{ ref('dex_solana_trades') }}
where 
      project = 'meteora'
      and version = 2