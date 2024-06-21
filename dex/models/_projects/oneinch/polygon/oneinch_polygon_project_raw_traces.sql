{% set blockchain = 'polygon' %}



{{
    config(
        schema = 'oneinch_' + blockchain,
        alias = 'project_raw_traces',
        partition_by = ['block_date'],
        materialized = 'incremental',
        file_format = 'delta',
        incremental_strategy = 'merge',
        incremental_predicates = [incremental_predicate('DBT_INTERNAL_DEST.block_time')],
        unique_key = ['tx_hash', 'trace_address']
    )
}}



{{
    oneinch_project_raw_traces_macro(
        blockchain = blockchain
    )
}}
