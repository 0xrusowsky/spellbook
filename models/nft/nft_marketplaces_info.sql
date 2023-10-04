{{ config(
        tags = ['dunesql', 'static'],
        schema='nft',
        alias = alias('marketplaces_info'),
        unique_key = ['codename'],
        post_hook='{{ expose_spells(\'["ethereum", "polygon", "bnb", "avalanche_c", "gnosis", "fantom", "optimism", "arbitrum", "celo", "base"]\',
                                    "sector",
                                    "nft",
                                    \'["hildobby"]\') }}')
}}

SELECT project, name, marketplace_type, x_username
FROM (VALUES
    ('opensea', 'OpenSea', 'Direct', 'opensea')
    , ('cryptopunks', 'CryptoPunks', 'Direct', 'cryptopunksnfts')
    , ('looksrare', 'LooksRare', 'Direct', 'LooksRare')
    , ('x2y2', 'X2Y2', 'Direct & Aggregator', 'the_x2y2')
    , ('blur', 'Blur', 'Direct & Aggregator', 'blur_io')
    , ('gem', 'Gem', 'Aggregator', 'Uniswap')
    , ('opensea_pro', 'OpenSea Pro', 'Aggregator', 'openseapro')
    , ('genie', 'Genie', 'Aggregator', 'geniexyz')
    , ('foundation', 'Foundation', 'Direct', 'foundation')
    , ('sudoswap', 'Sudoswap', 'Direct', 'sudoswap')
    , ('element', 'Element', 'Direct & Aggregator', 'Element_Market')
    , ('archipelago', 'Archipelago', 'Direct', 'archipelago_art')
    , ('rarible', 'Rarible', 'Aggregator', 'rarible')
    , ('artblocks', 'Art Blocks', 'Direct', 'artblocks_io')
    , ('superrare', 'SuperRare', 'Direct', 'SuperRare')
    , ('universe', 'Universe', 'Direct', 'universe_xyz')
    , ('knownorigin', 'Known Origin', 'Direct', 'KnownOrigin_io')
    , ('zeroex', '0x', 'Direct', '0xproject')
    , ('infinity', 'Infinity', 'Direct', NULL)
    , ('zora', 'Zora', 'Direct', 'ourZORA')
    , ('reservoir', 'Reservoir', 'Aggregator', 'reservoir0x')
    , ('alpha sharks', 'Alpha Sharks', 'Aggregator', 'AlphaSharksNFT')
    , ('uniswap', 'Uniswap', 'Aggregator', 'Uniswap')
    , ('okx', 'OKX', 'Aggregator', 'okx')
    , ('bitkeep', 'BitKeep', 'Aggregator', 'BitgetWallet')
    , ('magic eden', 'Magic Eden', 'Aggregator', 'MagicEden')
    , ('rarity garden', 'Rarity Garden', 'Aggregator', 'rarity_garden')
    , ('nftinit', 'NFTInit', 'Aggregator', 'NFTinitcom')
    , ('flip', 'Flip', 'Aggregator', 'Flip_xyz')
    , ('tiny astro', 'Tiny Astro', 'Aggregator', 'tinyastroNFT')
    , ('gigamart', 'GigaMart', 'Aggregator', 'GigaMartNFT')
    , ('nftrade', 'NFTrade', 'Direct', 'NFTradeOfficial')
    , ('quix', 'Quix', 'Direct', NULL)
    , ('bluesweep', 'bluesweep', 'Aggregator', 'bluesweep_xyz')
    , ('pancakeswap', 'PancakeSwap', 'Direct', 'PancakeSwap')
    , ('magiceden', 'MagicEden', 'Direct', 'MagicEden')
    , ('oxalus', 'Oxalus', 'Aggregator', 'Oxalus_io')
    , ('tofu', 'tofuNFT', 'Direct', 'tofuNFT')
    , ('skillet', 'Skillet', 'Aggregator', 'SkilletNFT')
    , ('nftb', 'NFTb', 'Direct', 'nftbmarket')
    , ('liquidifty', 'Liquidifty', 'Direct', 'liquidifty')
    , ('nftx', 'NFTX', 'Direct', 'NFTX_')
    , ('zonic', 'Zonic', 'Direct', 'ZonicApp')
    , ('nftearth', 'NFTΞarth', 'Direct', 'NFTEarth_L2')
    , ('trove', 'Trove', 'Direct', 'TroverseNFT')
    , ('aavegotchi', 'Aavegotchi', 'Direct', 'aavegotchi')
    , ('oneplanet', 'OnePlanet', 'Direct', 'oneplanet')
    , ('fractal', 'Fractal', 'Direct', 'fractalwagmi')
    , ('dew', 'Dew', 'Aggregator', 'Dew_HQ')
    , ('stealcam', 'Stealcam', 'Direct', 'trystealcam')
    , ('collectionswap', 'Collectionswap', 'Direct', 'collectionswap')
    , ('decentraland', 'Decentraland', 'Direct', 'decentraland')
    ) AS temp_table (project, name, marketplace_type, x_username)