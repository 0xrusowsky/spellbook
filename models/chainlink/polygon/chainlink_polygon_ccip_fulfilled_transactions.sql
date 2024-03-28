{{
  config(
    alias='ccip_fulfilled_transactions',
    materialized='incremental',
    file_format='delta',
    incremental_strategy='merge',
    unique_key=['tx_hash', 'tx_index', 'caller_address']
  )
}}

{% set incremental_interval = '7' %}

WITH
  ccip_fulfilled_transactions AS (
    SELECT
      ccip_send_logs_v1.tx_hash as tx_hash,
      ccip_send_logs_v1.block_time as block_time,
      cast(date_trunc('day', ccip_send_logs_v1.block_time) as date) as date_start,
      ccip_send_logs_v1.tx_from as caller_address,
      ccip_send_logs_v1.tx_index as tx_index
    FROM
      {{ ref('chainlink_polygon_ccip_send_requested_logs_v1') }} ccip_send_logs_v1
      LEFT JOIN {{ source('polygon', 'transactions') }} tx ON
        ccip_send_logs_v1.tx_hash = tx.hash
        {% if is_incremental() %}
            AND tx.block_time >= date_trunc('day', now() - interval '{{incremental_interval}}' day)
        {% endif %}
      WHERE
        tx.success = true
      {% if is_incremental() %}
        AND ccip_send_logs_v1.block_time >= date_trunc('day', now() - interval '{{incremental_interval}}' day)
      {% endif %}

    UNION

    SELECT
      ccip_send_logs_v1_2.tx_hash as tx_hash,
      ccip_send_logs_v1_2.block_time as block_time,
      cast(date_trunc('day', ccip_send_logs_v1_2.block_time) as date) as date_start,
      ccip_send_logs_v1_2.tx_from as caller_address,
      ccip_send_logs_v1_2.tx_index as tx_index
    FROM
      {{ ref('chainlink_polygon_ccip_send_requested_logs_v1_2') }} ccip_send_logs_v1_2
      LEFT JOIN {{ source('polygon', 'transactions') }} tx ON
        ccip_send_logs_v1_2.tx_hash = tx.hash
        {% if is_incremental() %}
            AND tx.block_time >= date_trunc('day', now() - interval '{{incremental_interval}}' day)
        {% endif %}
      WHERE
        tx.success = true
      {% if is_incremental() %}
        AND ccip_send_logs_v1_2.block_time >= date_trunc('day', now() - interval '{{incremental_interval}}' day)
      {% endif %}
        
  )
SELECT
 'polygon' as blockchain,
  block_time,
  date_start,
  caller_address,
  tx_hash,
  tx_index
FROM
  ccip_fulfilled_transactions