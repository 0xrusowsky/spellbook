-- copied over from balances ethereum tests 

select amount
from {{ ref('balances_optimism_erc20_hour') }} bal
where round(amount/power(10, 18), 6) < 0
and symbol in ('AAVE', 'DAI', 'UNI', 'LINK')
and bal.hour > now() - interval '2' Day

