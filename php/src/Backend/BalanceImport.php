<?php

namespace AlphaRock\Alpha\QuickSight\Backend;

use AlphaRock\Core\Common\Time;
use AlphaRock\Core\Database\Query\SQL;
use AlphaRock\Core\Static\BackendCluster;
use AlphaRock\Core\Static\Log;
use AlphaRock\Alpha\QuickSight\Helper\FxCache;
use AlphaRock\Core\Static\MonkeyCluster;
use AlphaRock\Core\Static\Underlying;

class BalanceImport
{
    public static function balanceForTimestamp(string $timestamp, int $n = 1)
    {
        Time::toFormat($timestamp, Time::MYSQL_MINUTE);
        if ($n > 1) {
            Log::debug("Balance import for timestamp {$timestamp} in Loop mode");
            Log::debug("n=$n");
        }

        for ($i = 1; $i <= $n; $i++) {
            static::getBalances($timestamp, $i);
            $timestamp = Time::generate($timestamp, Time::MYSQL_MINUTE, '+1 minute');
        }
    }

    public static function getBalances(string $timestamp, int $i)
    {
        $tradingDay = Time::generate($timestamp, Time::MYSQL_DATE);
        $tradingMin = Time::generate($timestamp, Time::MYSQL_MINUTE);
        $timeOfDay = Time::generate($timestamp, Time::TIME_MINUTE);

        $sql = SQL::fromFile(
            filepath: __DIR__ . '/SQL/balance.sql',
            replacements: [
                "{cutOffTimestamp}" => $tradingMin
            ]
        );
        $result = BackendCluster::query($sql);
        $rowCount = $result->getRowCount();

        $insert = [];

        $total = 0;
        foreach ($result->fetchAll() as $row) {
            $fx = FxCache::getFxRate($row->ts, $row->underlying_id);
            $positionUsd = $row->margin_balance * $fx;
            $total += $positionUsd;
            $posType = match(Underlying::details($row->underlying_id)->type){
                "fiat" => "fiat_usd",
                "stable_coin" => "stable_usd",
                "crypto" => "crypto_usd",
                default => "crypto_usd"
            };
            $insert[$row->account_id] ??= [
                "trading_day" => $tradingDay,
                "trading_minute" => $tradingMin,
                "time_of_day" => $timeOfDay,
                "exchange_id" => $row->exchange_id,
                "account_id" => $row->account_id,
                "balance_usd" => 0,
                "fiat_usd" => 0,
                "stable_usd" => 0,
                "crypto_usd" => 0
            ];
            $insert[$row->account_id]["balance_usd"] += $positionUsd;
            $insert[$row->account_id][$posType] += $positionUsd;
        }
        $total = round($total, 2);

        foreach (array_chunk(array_values($insert), 5000) as $chunk) {
            MonkeyCluster::query(
                "INSERT INTO quicksight.balance_by_minute",
                $chunk,
                "ON CONFLICT(trading_minute, account_id) DO NOTHING"
            );
        }

        Log::info("[$i] $timestamp => $total $ ($rowCount positions)");
    }
}
