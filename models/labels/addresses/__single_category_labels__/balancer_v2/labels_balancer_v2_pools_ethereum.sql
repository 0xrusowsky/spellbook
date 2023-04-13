{{config(
    alias='balancer_v2_pools_ethereum',
    materialized = 'incremental',
    file_format = 'delta',
    incremental_strategy = 'merge',
    unique_key = ['address'],
    post_hook='{{ expose_spells(\'["ethereum"]\',
                                     "sector",
                                    "labels",
                                    \'["balancerlabs"]\') }}'
    )
}}

WITH pools AS (
    SELECT pool_id, zip.tokens AS token_address,  zip.weights/pow(10, 18) AS normalized_weight, symbol, pool_type
    FROM (
        SELECT c.poolId AS pool_id, explode(arrays_zip(cc.tokens, cc.weights)) AS zip, cc.symbol, 'WP' AS pool_type
        FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
        INNER JOIN {{ source('balancer_v2_ethereum', 'WeightedPoolFactory_call_create') }} cc
        ON c.evt_tx_hash = cc.call_tx_hash
        AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
        {% if is_incremental() %}
        WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
            AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
        {% endif %}
    )

    UNION ALL

    SELECT pool_id, zip.tokens AS token_address,  zip.normalizedWeights/pow(10, 18) AS normalized_weight, symbol, pool_type
    FROM (
        SELECT c.poolId AS pool_id, explode(arrays_zip(cc.tokens, cc.normalizedWeights)) AS zip, cc.symbol, 'WP' AS pool_type
        FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
        INNER JOIN {{ source('balancer_v2_ethereum', 'WeightedPoolV2Factory_call_create') }} cc
        ON c.evt_tx_hash = cc.call_tx_hash
        AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
        {% if is_incremental() %}
        WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
            AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
        {% endif %}
    )

    UNION ALL

    SELECT pool_id, zip.tokens AS token_address,  zip.weights/pow(10, 18) AS normalized_weight, symbol, pool_type
    FROM (
        SELECT c.poolId AS pool_id, explode(arrays_zip(cc.tokens, cc.weights)) AS zip, cc.symbol, 'WP2T' AS pool_type
        FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
        INNER JOIN {{ source('balancer_v2_ethereum', 'WeightedPool2TokensFactory_call_create') }} cc
        ON c.evt_tx_hash = cc.call_tx_hash
        AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
        {% if is_incremental() %}
        WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
            AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
        {% endif %}
    )

    UNION ALL

    SELECT pool_id, zip.tokens AS token_address,  zip.weights/pow(10, 18) AS normalized_weight, symbol, pool_type
    FROM (
        SELECT c.poolId AS pool_id, explode(arrays_zip(cc.tokens, cc.weights)) AS zip, cc.symbol, 'IP' AS pool_type
        FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
        INNER JOIN {{ source('balancer_v2_ethereum', 'InvestmentPoolFactory_call_create') }} cc
        ON c.evt_tx_hash = cc.call_tx_hash
        AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
        {% if is_incremental() %}
        WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
            AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
        {% endif %}
    )

    UNION ALL

    SELECT c.poolId AS pool_id, explode(cc.tokens) AS token_address, NULL AS normalized_weight, cc.symbol, 'SP' AS pool_type
    FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
    INNER JOIN {{ source('balancer_v2_ethereum', 'StablePoolFactory_call_create') }} cc
    ON c.evt_tx_hash = cc.call_tx_hash
    AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
    {% if is_incremental() %}
    WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
        AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
    {% endif %}

    UNION ALL

    SELECT c.poolId AS pool_id, explode(cc.tokens) AS token_address, CAST(NULL AS DOUBLE) AS normalized_weight, cc.symbol, 'SP' AS pool_type
    FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
    INNER JOIN {{ source('balancer_v2_ethereum', 'MetaStablePoolFactory_call_create') }} cc
    ON c.evt_tx_hash = cc.call_tx_hash
    AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
    {% if is_incremental() %}
    WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
        AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
    {% endif %}

    UNION ALL

    SELECT c.poolId AS pool_id, explode(cc.tokens) AS token_address, 0 AS normalized_weight, cc.symbol, 'LBP' AS pool_type
    FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
    INNER JOIN {{ source('balancer_v2_ethereum', 'LiquidityBootstrappingPoolFactory_call_create') }} cc
    ON c.evt_tx_hash = cc.call_tx_hash
    AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
    {% if is_incremental() %}
    WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
        AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
    {% endif %}

    UNION ALL

    SELECT c.poolId AS pool_id, explode(cc.tokens) AS token_address, 0 AS normalized_weight, cc.symbol, 'LBP' AS pool_type
    FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
    INNER JOIN {{ source('balancer_v2_ethereum', 'NoProtocolFeeLiquidityBootstrappingPoolFactory_call_create') }} cc
    ON c.evt_tx_hash = cc.call_tx_hash
    AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
    {% if is_incremental() %}
    WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
        AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
    {% endif %}

    UNION ALL

    SELECT c.poolId AS pool_id, explode(cc.tokens) AS token_address, CAST(NULL AS DOUBLE) AS normalized_weight, cc.symbol, 'SP' AS pool_type
    FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
    INNER JOIN {{ source('balancer_v2_ethereum', 'StablePhantomPoolFactory_call_create') }} cc
    ON c.evt_tx_hash = cc.call_tx_hash
    AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
    {% if is_incremental() %}
    WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
        AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
    {% endif %}

    UNION ALL

    SELECT c.poolId AS pool_id, explode(cc.tokens) AS token_address, CAST(NULL AS DOUBLE) AS normalized_weight, cc.symbol, 'SP' AS pool_type
    FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
    INNER JOIN {{ source('balancer_v2_ethereum', 'ComposableStablePoolFactory_call_create') }} cc
    ON c.evt_tx_hash = cc.call_tx_hash
    AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
    {% if is_incremental() %}
    WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
        AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
    {% endif %}

    UNION ALL

    SELECT c.poolId AS pool_id, explode(array(cc.mainToken, cc.wrappedToken)) AS zip, CAST(NULL AS DOUBLE) AS normalized_weight, cc.symbol, 'LP' AS pool_type
    FROM {{ source('balancer_v2_ethereum', 'Vault_evt_PoolRegistered') }} c
    INNER JOIN {{ source('balancer_v2_ethereum', 'AaveLinearPoolFactory_call_create') }} cc
    ON c.evt_tx_hash = cc.call_tx_hash
    AND SUBSTRING(c.poolId, 0, 42) = cc.output_0
    {% if is_incremental() %}
    WHERE c.evt_block_time >= date_trunc("day", now() - interval '7 day')
        AND cc.call_block_time >= date_trunc("day", now() - interval '7 day')
    {% endif %}
),

settings AS (
    SELECT pool_id,
    coalesce(t.symbol,'?') AS token_symbol,
    normalized_weight,
    p.symbol AS pool_symbol,
    p.pool_type
    FROM pools p
    LEFT JOIN tokens.erc20 t ON p.token_address = t.contract_address
)

SELECT
  'ethereum' AS blockchain,
  SUBSTRING(pool_id, 0, 42) AS address,
  CASE WHEN array_contains(array('SP', 'LP', 'LBP'), pool_type) THEN lower(pool_symbol)
  ELSE lower(concat(array_join(array_sort(collect_list(token_symbol)), '/'), ' ', array_join(collect_list(cast(norm_weight AS string)), '/')))
  END AS name,
  'balancer_v2_pool' AS category,
  'balancerlabs' AS contributor,
  'query' AS source,
  timestamp('2022-12-23') AS created_at,
  now() AS updated_at,
  'balancer_v2_pools_ethereum' AS model_name,
  'identifier' as label_type
FROM   (
    SELECT s1.pool_id, token_symbol, pool_symbol, cast(100*normalized_weight AS integer) AS norm_weight, pool_type FROM settings s1
    ORDER BY 1 ASC , 3 DESC, 2 ASC
) s
GROUP BY pool_id, pool_symbol, pool_type
ORDER BY 1