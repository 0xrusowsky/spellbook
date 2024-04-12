{{ config(
    schema = 'dex'
    , alias = 'base_lps'
    , partition_by = ['block_month', 'blockchain', 'project']
    , materialized = 'incremental'
    , file_format = 'delta'
    , incremental_strategy = 'merge'
    , unique_key = ['blockchain', 'project', 'version', 'tx_hash', 'evt_index', 'vault_address']
    , incremental_predicates = [incremental_predicate('DBT_INTERNAL_DEST.block_time')]
    )
}}

{% set models = [
    ref('alm_ethereum_base_trades')
] %}

WITH base_union AS (
    SELECT *
    FROM (
        {% for base_model in base_models %}
        SELECT
            blockchain
            , project
            , version
            , block_time
            , block_month
            , block_number
            , pool_address
            , vault_address
            , token0_address
            , token1_address
--             , volume_usd
--             , volume0
--             , volume1
            , volume0_raw
            , volume1_raw
            , row_number() over (partition by tx_hash, evt_index, vault_address order by tx_hash asc, evt_index asc) as duplicates_rank
        FROM 
            {{ base_model }}
        {% if is_incremental() %}
        WHERE
            {{ incremental_predicate('block_time') }}
        {% endif %}
        {% if not loop.last %}
        UNION ALL
        {% endif %}
        {% endfor %}
    )
    WHERE
        duplicates_rank = 1
)

select
    *
from
    base_union
