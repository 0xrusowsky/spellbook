{% macro transfers_base(blockchain, traces, transactions, erc20_transfers, native_contract_address = null) %}
{%- set token_standard_20 = 'bep20' if blockchain == 'bnb' else 'erc20' -%}

WITH transfers AS (
    SELECT
        block_date
        , block_time
        , block_number
        , tx_hash
        , cast(NULL as bigint) AS evt_index
        , -CAST(ROW_NUMBER() OVER (PARTITION BY block_number, tx_hash ORDER BY "from", to, value) AS INT256) AS sub_tx_trade_id
        , trace_address
        {% if native_contract_address%}
        , {{native_contract_address}} AS contract_address 
        {% else %}
        , CAST(NULL AS varbinary) AS contract_address 
        {% endif %}
        , 'native' AS token_standard
        , "from"
        , to
        , value AS amount_raw
    FROM {{ traces }}
    WHERE success
        AND (call_type NOT IN ('delegatecall', 'callcode', 'staticcall') OR call_type IS null)
        AND value > UINT256 '0'
        {% if is_incremental() %}
        AND {{incremental_predicate('block_time')}}
        {% endif %}
    AND block_time > NOW() - interval '1' day

    UNION ALL

    SELECT 
        cast(date_trunc('day', t.evt_block_time) as date) AS block_date
        , t.evt_block_time AS block_time
        , t.evt_block_number AS block_number
        , t.evt_tx_hash AS tx_hash
        , t.evt_index
        , t.evt_index AS sub_tx_trade_id
        , CAST(NULL AS ARRAY<BIGINT>) AS trace_address
        , t.contract_address
        , CASE
            WHEN t.contract_address =     
                {% if native_contract_address %}
                    {{native_contract_address}}
                {% else %}
                    CAST(NULL AS varbinary)
                {% endif %}
            THEN 'native'
            ELSE '{{token_standard_20}}'
            END AS token_standard
        , t."from"
        , t.to
        , t.value AS amount_raw
    FROM {{ erc20_transfers }} t
    WHERE block_time > NOW() - interval '1' day
    {% if is_incremental() %}
    AND {{incremental_predicate('evt_block_time')}}
    {% endif %}
)

SELECT 
    -- We have to create this unique key because evt_index and trace_address can be null
    {{dbt_utils.generate_surrogate_key(['t.block_number', 'tx.index', 't.evt_index', "array_join(t.trace_address, ',')"])}} as unique_key
    , '{{blockchain}}' as blockchain
    , t.block_date
    , t.block_time
    , t.block_number
    , t.tx_hash
    , t.evt_index
    , t.sub_tx_trade_id
    , t.trace_address
    , t.token_standard
    , tx."from" AS tx_from
    , tx."to" AS tx_to
    , tx."index" AS tx_index
    , t."from"
    , t.to
    , t.contract_address
    , t.amount_raw
FROM transfers t
INNER JOIN {{ transactions }} tx ON
    {% if blockchain == 'gnosis' %}
    cast(date_trunc('day', tx.block_time) as date) = t.block_date --gnosis does not have block_date in transactions, force block_time to be date
    {% else %}
    tx.block_date = t.block_date --partition column in raw base tables (traces, transactions)
    {% endif %}
    AND tx.block_number = t.block_number
    AND tx.hash = t.tx_hash
    AND t.block_time > NOW() - interval '1' day
    {% if is_incremental() %}
    AND {{incremental_predicate('tx.block_time')}}
    {% endif %}
{% endmacro %}