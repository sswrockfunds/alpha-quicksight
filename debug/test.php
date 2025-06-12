#!/usr/bin/env php
<?php

use AlphaRock\Core\Cli\CliParser;
use AlphaRock\Core\Common\Time;
use AlphaRock\Core\Static\Log;
use AlphaRock\Core\Static\MonkeyCluster;
use AlphaRock\Core\Static\QuantCluster;

require_once __DIR__ . "/../php/src/alpha-quicksight.php";

$Cli = new CliParser($argv);
$ts = $Cli->getArg(0) ?? Time::today(-1);
Time::toDate($ts);
# 2024-09-30 12k
# 2024-01-01

# 2022-11-12
# 2023-02-19

$quantSQL = <<<SQL
    SELECT account_id, round(balance_usd) as balance_usd
      FROM cs_balances c
     WHERE c.trading_date='$ts'
  ORDER BY account_id asc
SQL;

$monkeySQL = <<<SQL
    SELECT account_id, round(exposure_usd) as exposure_usd
    FROM quicksight._history
    WHERE trading_day='$ts'
SQL;


$data = [];
$vTotal = 0;
$mTotal = 0;
foreach(QuantCluster::fetchAll($quantSQL) as $day){
    $data[$day->account_id] = (object)[
        "vault" => $day->balance_usd,
        "monkeyBi" => null,
        "delta" => null
    ];
    $vTotal += $day->balance_usd;
}

foreach(MonkeyCluster::fetchAll($monkeySQL) as $day){
    $data[$day->account_id] ??= (object)[
        "vault" => 0,
        "monkeyBi" => null,
        "delta" => null
    ];
    $data[$day->account_id]->monkeyBi = $day->exposure_usd;
    $data[$day->account_id]->delta = $day->exposure_usd - $data[$day->account_id]->vault;
    $mTotal += $day->exposure_usd;
}

Log::info("Data for day $ts");
foreach($data as $accountId => $a){
    $mismatch = $a->delta === null && (abs($a->vault) >0 || abs($a->monkeyBi) > 0);
    if(abs($a->delta) > 3 ){
        Log::warning("Account $accountId\n".json_encode($a, JSON_PRETTY_PRINT));
    }
}

Log::info("   vault: $vTotal");
Log::info("monkeyBI: $mTotal");
#print json_encode($data, JSON_PRETTY_PRINT);
