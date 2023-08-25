{{
  config(
    tags=['dunesql'],
    alias=alias('ocr_fulfilled_transactions'),
    partition_by=['date_month'],
    materialized='incremental',
    file_format='delta',
    incremental_strategy='merge',
    unique_key=['tx_hash', 'tx_index', 'node_address'],
    post_hook='{{ expose_spells(\'["optimism"]\',
                                "project",
                                "chainlink",
                                \'["linkpool_ryan"]\') }}'
  )
}}

{% set incremental_interval = '7' %}

WITH
  optimism_usd AS (
    SELECT
      minute as block_time,
      price as usd_amount
    FROM
      {{ source('prices', 'usd') }} price
    WHERE
      symbol = 'ETH'
      {% if is_incremental() %}
        AND minute >= date_trunc('day', now() - interval '{{incremental_interval}}' day)
      {% endif %}      
  ),
  ocr_fulfilled_transactions AS (
    SELECT
      tx.hash as tx_hash,
      tx.index as tx_index,
      MAX(tx.block_time) as block_time,
      cast(date_trunc('month', MAX(tx.block_time)) as date) as date_month,
      tx."from" as "node_address",
      MAX(
        (cast((l1_gas_used) as double) / 1e18) * l1_gas_price
      ) as token_amount,
      MAX(optimism_usd.usd_amount) as usd_amount
    FROM
      {{ source('optimism', 'transactions') }} tx
      RIGHT JOIN {{ ref('chainlink_optimism_ocr_gas_transmission_logs') }} ocr_gas_transmission_logs ON ocr_gas_transmission_logs.tx_hash = tx.hash
      LEFT JOIN optimism_usd ON date_trunc('minute', tx.block_time) = optimism_usd.block_time
    {% if is_incremental() %}
      WHERE tx.block_time >= date_trunc('day', now() - interval '{{incremental_interval}}' day)
    {% endif %}      
    GROUP BY
      tx.hash,
      tx.index,
      tx."from"
  )
SELECT
 'optimism' as blockchain,
  block_time,
  date_month,
  node_address,
  token_amount,
  usd_amount,
  tx_hash,
  tx_index
FROM
  ocr_fulfilled_transactions