#!/usr/bin/env php
<?php

use AlphaRock\Core\Cli\CliParser;
use AlphaRock\Core\Common\Time;
use AlphaRock\Core\Static\Log;
use AlphaRock\Core\Static\MonkeyCluster;
use AlphaRock\Core\Static\QuantCluster;

require_once __DIR__ . "/../php/src/alpha-quicksight.php";


$sql = <<<SQL
SELECT trading_date as trading_day,
			 account_id,
       null as account_name,
       "UID" as account_uid,

       CASE WHEN prod='yes' THEN TRUE
            ELSE FALSE
       END active,

       null main_account_id,
       market_id as exchange_id,

       CASE WHEN "usage_prim" LIKE 'Main' THEN 'main'
       		  WHEN "usage_prim" LIKE 'Custody' THEN 'main'
            WHEN "usage_prim" LIKE '%esting%' THEN 'testing'
            WHEN "usage_prim" LIKE 'Hedge' THEN 'hedge'
            WHEN "usage_prim" LIKE 'IEO' THEN 'ieo'
            WHEN "usage_prim" LIKE 'Trading' THEN 'production'
            WHEN "usage_prim" LIKE 'Activity' THEN 'activity'
            WHEN "usage_prim" LIKE 'Timo' THEN 'testing'
            WHEN "usage_prim" LIKE 'RPI' THEN 'testing'
            WHEN "strategy" LIKE 'Testing' THEN 'testing'
            WHEN "strategy" LIKE 'Timo' THEN 'testing'
            ELSE null
       END account_type,


       CASE WHEN "strategy" LIKE 'Alphaflexx' THEN 'Alphaflexx'
       		  WHEN "strategy" LIKE 'Alphaflexx Hedge' THEN 'Alphaflexx Hedge'
            WHEN "strategy" LIKE 'Sonic' THEN 'Alphaflexx Hedge'
            WHEN "strategy" LIKE 'Hedge' THEN 'Hedge'
            WHEN "strategy" LIKE 'Hedge' THEN 'Hedge'
            WHEN "strategy" LIKE 'Basis%' THEN 'BasisTrade'
            WHEN "strategy" LIKE 'CarryTrader' THEN 'CarryTrader'
            WHEN "strategy" LIKE 'EUR' THEN 'Alphaflexx'
            --
            WHEN "strategy" LIKE 'FundingTrader' THEN 'FundingTrader'
            WHEN "strategy" LIKE 'Impact' THEN 'Impact'
            WHEN "strategy" LIKE 'Maverick' THEN 'Maverick'
            WHEN "strategy" LIKE 'Paradigm' THEN 'Paradigm'
            WHEN "strategy" LIKE 'Scythe' THEN 'Scythe'
            WHEN "strategy" LIKE 'Seeder' THEN 'Seeder'
            WHEN "strategy" LIKE 'MarketMaking' THEN 'MarketMaking'
            WHEN "strategy" LIKE 'GIB Strategies' THEN 'GIB Strategies'
            --
            WHEN "strategy" LIKE 'RPI' THEN 'RPI'
            ELSE null
       END as strategy,

       CASE WHEN "instrumentTyp" LIKE 'DERIV%' THEN 'derivate'
            WHEN "instrumentTyp" LIKE '%pot/Deriv%' THEN 'multi'
            WHEN "instrumentTyp" LIKE 'EUR%' THEN 'spot'
            WHEN "instrumentTyp" LIKE '%pot%' THEN 'spot'
            ELSE null
       END instrument_type,

       CASE WHEN "server" LIKE '%-%' THEN null
            ELSE "server"
       END as "server",
       "counterUnderlying" as counter_underlying,

       CASE WHEN "strategy" LIKE 'Basis%' THEN 'Lukas'
            WHEN "strategy" LIKE 'CarryTrader' THEN 'Lukas'
            --
            WHEN "strategy" LIKE 'FundingTrader' THEN 'Timo'
            WHEN "strategy" LIKE 'Impact' THEN 'Timo'
            WHEN "strategy" LIKE 'Maverick' THEN 'AlphaRock'
            WHEN "strategy" LIKE 'Paradigm' THEN 'Paradigm'
            WHEN "strategy" LIKE 'Scythe' THEN 'Timo'
            WHEN "strategy" LIKE 'Seeder' THEN 'AlphaRock'
            WHEN "strategy" LIKE 'MarketMaking' THEN 'AlphaRock'
            WHEN "strategy" LIKE 'GIB Strategies' THEN 'AlphaRock'
            --
            WHEN "strategy" LIKE 'RPI' THEN 'Jonas'
            ELSE 'AlphaRock'
       END as "owner",

       'none' as portfolio,
       FALSE as custody,
       FALSE as collateral,
       FALSE as cap_distributor,
       FALSE as morpheus_check,
       FALSE as coinmover,
       'none' as af_mode,
       "comment",
       current_TIMESTAMP::timestamp(0) as updated_ts
  FROM qs.accounts
 WHERE account_id is not null
SQL;

$result = QuantCluster::query($sql);

$batch = [];
$limit = 1000;

while ($row = $result->fetch()) {
    $batch[] = $row;

    if (count($batch) >= $limit) {
        MonkeyCluster::query('INSERT INTO account.history', $batch, 'ON CONFLICT(trading_day, account_id) DO NOTHING');
        $lastTs = $batch[count($batch) - 1]->trading_day;
        $batch = [];
        Log::info("Inserted $limit entries into account.history ($lastTs)");
    }
}

if ($batch) {
    MonkeyCluster::query('INSERT INTO account.history', $batch, 'ON CONFLICT(trading_day, account_id) DO NOTHING');
}

