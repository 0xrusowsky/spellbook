 {{
  config(
        alias='trades'
  )
}}

SELECT 
  'solana' as blockchain,
  'opensea' as project,
  'v1' as version,
  signatures[0] as tx_hash, 
  block_time,
  abs(post_balances[0] / 1e9 - pre_balances[0] / 1e9) * p.price AS amount_usd,
  abs(post_balances[0] / 1e9 - pre_balances[0] / 1e9) AS amount_original,
  abs(post_balances[0] - pre_balances[0])::string AS amount_raw,
  p.symbol as currency_symbol,
  p.contract_address as currency_contract,
  'pAHAKoTJsAAe2ZcvTZUxoYzuygVAFAmbYmJYdWT886r' as project_contract_address,
  CASE WHEN ARRAY_CONTAINS(log_messages, 'Program log: Instruction: ExecuteSale') THEN 'Trade' 
  END as evt_type,
  signatures[0] || '-' || id as unique_trade_id
FROM {{ source('solana','transactions') }}
LEFT JOIN {{ source('prices', 'usd') }} p 
  ON p.minute = date_trunc('minute', block_time)
  AND p.symbol = 'SOL'
WHERE (array_contains(account_keys, '3o9d13qUvEuuauhFrVom1vuCzgNsJifeaBYDPquaT73Y')
       OR array_contains(account_keys, 'pAHAKoTJsAAe2ZcvTZUxoYzuygVAFAmbYmJYdWT886r'))
AND block_date > '2022-04-06'
AND ARRAY_CONTAINS(log_messages, 'Program log: Instruction: ExecuteSale')