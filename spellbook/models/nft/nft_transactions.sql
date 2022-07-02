{{ config(
        alias ='transactions',
        materialized ='incremental'
        )
}}


SELECT * FROM {{ ref('opensea_transactions') }} 
         UNION
SELECT * FROM {{ ref('magiceden_transactions') }}

{% if is_incremental() %}
-- this filter will only be applied on an incremental run
WHERE block_time > now() - interval 2 days
{% endif %} 