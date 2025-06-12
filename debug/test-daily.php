#!/usr/bin/env php
<?php

use AlphaRock\Core\Common\Time;
use AlphaRock\Core\Static\Log;
use AlphaRock\Core\Static\MonkeyCluster;
use AlphaRock\Core\Static\QuantCluster;

require_once __DIR__ . "/../php/src/alpha-quicksight.php";

$quantSQL = <<<SQL
    SELECT c.trading_date as day, round(sum(c.balance_usd)) as balance_usd
      FROM cs_balances c
   --  WHERE c.trading_date>='2024-01-01'
  GROUP BY c.trading_date
SQL;

$monkeySQL = <<<SQL
    SELECT m.trading_day as day, round(sum(m.exposure_usd)) as exposure_usd
    FROM quicksight._history m
   -- WHERE m.trading_day>='2024-01-01'
    GROUP BY m.trading_day
SQL;


$data = [];
foreach(QuantCluster::fetchAll($quantSQL) as $row){
    Time::toDate($row->day);
    $data[$row->day] ??= (object)[
        "vault" => 0,
        "monkeyBi" => 0,
        "delta" => null
    ];
    $data[$row->day]->vault += $row->balance_usd;
}

foreach(MonkeyCluster::fetchAll($monkeySQL) as $row){
    Time::toDate($row->day);
    $data[$row->day] ??= (object)[
        "vault" => 0,
        "monkeyBi" => 0,
        "delta" => null
    ];
    $data[$row->day]->monkeyBi += $row->exposure_usd;
    $data[$row->day]->delta = $data[$row->day]->monkeyBi - $data[$row->day]->vault;
}

foreach($data as $day => $a){
    if(abs($a->delta) > 0){
        Log::warning("Delta for day $day: $a->delta");
    }
}
#print json_encode($data, JSON_PRETTY_PRINT);
