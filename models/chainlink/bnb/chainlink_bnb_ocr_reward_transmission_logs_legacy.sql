{{ config( 
  alias = alias('ocr_reward_transmission_logs', legacy_model=True),
  tags = ['legacy']
  )
}}

-- TODO: Remove Dummy Table
SELECT
  1
