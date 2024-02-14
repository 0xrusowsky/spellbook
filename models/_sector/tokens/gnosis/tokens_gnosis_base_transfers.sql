{{config(
    tags = ['base_transfers_macro'],
    schema = 'tokens_gnosis',
    alias = 'base_transfers',
    partition_by = ['block_date'],
    materialized = 'incremental',
    file_format = 'delta',
    incremental_strategy = 'merge',
    incremental_predicates = [incremental_predicate('DBT_INTERNAL_DEST.block_time')],
    unique_key = ['unique_key'],
)
}}

{{transfers_base(
    blockchain='gnosis',
    traces = source('gnosis','traces'),
    transactions = source('gnosis','transactions'),
    erc20_transfers = source('erc20_gnosis','evt_transfer'),
    native_contract_address = null
)
}}
