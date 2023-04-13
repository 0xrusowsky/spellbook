{{ config(
    schema = 'uniswap_v3_ethereum',
    alias = 'trades',
    partition_by = ['block_date'],
    materialized = 'incremental',
    file_format = 'delta',
    incremental_strategy = 'merge',
    unique_key = ['block_date', 'blockchain', 'project', 'version', 'tx_hash', 'evt_index', 'trace_address'],
    post_hook='{{ expose_spells(\'["ethereum"]\',
                                "project",
                                "uniswap_v3",
                                \'["jeff-dude", "markusbkoch", "masquot", "milkyklim", "0xBoxer", "mewwts", "hagaetc"]\') }}'
    )
}}

{% set project_start_date = '2021-05-04' %}

WITH dexs AS
(
    --Uniswap v3
    SELECT
        CAST(t.evt_block_time AS TIMESTAMP(6) WITH TIME ZONE) AS block_time
        ,t.recipient AS taker
        ,'' AS maker
        ,CASE WHEN amount0 < CAST(0 AS INT256) THEN abs(amount0) ELSE abs(amount1) END AS token_bought_amount_raw -- when amount0 is negative it means trader_a is buying token0 from the pool
        ,CASE WHEN amount0 < CAST(0 AS INT256) THEN abs(amount1) ELSE abs(amount0) END AS token_sold_amount_raw
        ,NULL AS amount_usd
        ,CASE WHEN amount0 < CAST(0 AS INT256) THEN f.token0 ELSE f.token1 END AS token_bought_address
        ,CASE WHEN amount0 < CAST(0 AS INT256) THEN f.token1 ELSE f.token0 END AS token_sold_address
        ,CAST(t.contract_address AS VARCHAR) as project_contract_address
        ,t.evt_tx_hash AS tx_hash
        ,CAST('' AS VARCHAR(42)) AS trace_address
        ,t.evt_index
    FROM
        {{ source('uniswap_v3_ethereum', 'Pair_evt_Swap') }} t
    INNER JOIN {{ source('uniswap_v3_ethereum', 'Factory_evt_PoolCreated') }} f
        ON f.pool = t.contract_address
    {% if is_incremental() %}
    WHERE t.evt_block_time >= date_trunc("day", now() - interval '7 day')
    {% endif %}
)
SELECT
    'ethereum' AS blockchain
    ,'uniswap' AS project
    ,'3' AS version
    ,TRY_CAST(date_trunc('DAY', dexs.block_time) AS date) AS block_date
    ,dexs.block_time
    ,erc20a.symbol AS token_bought_symbol
    ,erc20b.symbol AS token_sold_symbol
    ,case
        when lower(erc20a.symbol) > lower(erc20b.symbol) then concat(erc20b.symbol, '-', erc20a.symbol)
        else concat(erc20a.symbol, '-', erc20b.symbol)
    end as token_pair
    ,dexs.token_bought_amount_raw / power(10, erc20a.decimals) AS token_bought_amount
    ,dexs.token_sold_amount_raw / power(10, erc20b.decimals) AS token_sold_amount
    ,CAST(dexs.token_bought_amount_raw AS DECIMAL(38,0)) AS token_bought_amount_raw
    ,CAST(dexs.token_sold_amount_raw AS DECIMAL(38,0)) AS token_sold_amount_raw
    ,coalesce(
        dexs.amount_usd
        ,(dexs.token_bought_amount_raw / power(10, p_bought.decimals)) * p_bought.price
        ,(dexs.token_sold_amount_raw / power(10, p_sold.decimals)) * p_sold.price
    ) AS amount_usd
    ,dexs.token_bought_address
    ,dexs.token_sold_address
    ,coalesce(dexs.taker, tx."from") AS taker -- subqueries rely on this COALESCE to avoid redundant joins with the transactions table
    ,dexs.maker
    ,dexs.project_contract_address
    ,dexs.tx_hash
    ,tx."from" AS tx_from
    ,tx.to AS tx_to
    ,dexs.trace_address
    ,dexs.evt_index
FROM dexs
INNER JOIN {{ source('ethereum', 'transactions') }} tx
    ON tx.hash = dexs.tx_hash
    {% if not is_incremental() %}
    AND tx.block_time >= CAST('{{project_start_date}}' AS TIMESTAMP(6) WITH TIME ZONE)
    {% endif %}
    {% if is_incremental() %}
    AND tx.block_time >= CAST(date_trunc("day", now() - interval '7 day') AS TIMESTAMP(6) WITH TIME ZONE)
    {% endif %}
LEFT JOIN {{ ref('tokens_erc20') }} erc20a
    ON erc20a.contract_address = CAST(dexs.token_bought_address as VARCHAR)
    AND erc20a.blockchain = 'ethereum'
LEFT JOIN {{ ref('tokens_erc20') }} erc20b
    ON erc20b.contract_address = CAST(dexs.token_sold_address as VARCHAR)
    AND erc20b.blockchain = 'ethereum'
LEFT JOIN {{ source('prices', 'usd') }} p_bought
    ON p_bought.minute = CAST(date_trunc('minute', dexs.block_time) AS TIMESTAMP(6) WITH TIME ZONE)
    AND p_bought.contract_address = CAST(dexs.token_bought_address as VARCHAR)
    AND p_bought.blockchain = 'ethereum'
    {% if not is_incremental() %}
    AND p_bought.minute >= CAST('{{project_start_date}}' AS TIMESTAMP(6) WITH TIME ZONE)
    {% endif %}
    {% if is_incremental() %}
    AND p_bought.minute >= CAST(date_trunc("day", now() - interval '7 day') AS TIMESTAMP(6) WITH TIME ZONE)
    {% endif %}
LEFT JOIN {{ source('prices', 'usd') }} p_sold
    ON p_sold.minute = CAST(date_trunc('minute', dexs.block_time) AS TIMESTAMP(6) WITH TIME ZONE)
    AND p_sold.contract_address = CAST(dexs.token_sold_address as VARCHAR)
    AND p_sold.blockchain = 'ethereum'
    {% if not is_incremental() %}
    AND p_sold.minute >= CAST('{{project_start_date}}' AS TIMESTAMP(6) WITH TIME ZONE)
    {% endif %}
    {% if is_incremental() %}
    AND p_sold.minute >= CAST(date_trunc("day", now() - interval '7 day') AS TIMESTAMP(6) WITH TIME ZONE)
    {% endif %}
