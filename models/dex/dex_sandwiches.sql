{{ config(
        tags=['dunesql'],
        schema='dex',
        alias = alias('sandwiches'),
        partition_by = ['block_month'],
        materialized = 'incremental',
        file_format = 'delta',
        incremental_strategy = 'merge',
        unique_key = ['blockchain', 'tx_hash', 'project_contract_address', 'evt_index'],
        post_hook='{{ expose_spells(\'["ethereum", "bnb", "avalanche_c", "gnosis", "optimism", "arbitrum", "fantom", "polygon", "base"]\',
                                "sector",
                                "dex",
                                \'["hildobby"]\') }}'
        )
}}

{% set sandwiches_models = [
     (ref('dex_arbitrum_sandwiches'))
     , (ref('dex_avalanche_c_sandwiches'))
     , (ref('dex_bnb_sandwiches'))
     , (ref('dex_ethereum_sandwiches'))
     , (ref('dex_fantom_sandwiches'))
     , (ref('dex_gnosis_sandwiches'))
     , (ref('dex_optimism_sandwiches'))
     , (ref('dex_polygon_sandwiches'))
     , (ref('dex_base_sandwiches'))
] %}

SELECT *
FROM (
        {% for sandwiches_model in sandwiches_models %}
        SELECT *
        FROM {{ sandwiches_model }}
        {% if is_incremental() %}
        WHERE block_time >= date_trunc('day', now() - interval '7' day)
        {% endif %}
        {% if not loop.last %}
        UNION ALL
        {% endif %}
        {% endfor %}
        )