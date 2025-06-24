<?php

namespace AlphaRock\Alpha\QuickSight\Cryptostruct;

use AlphaRock\Core\Common\Time;
use AlphaRock\Core\Masterdata\FxMinuteCache;
use AlphaRock\Core\Static\BackendCluster;
use AlphaRock\Core\Static\Log;
use AlphaRock\Core\Static\MonkeyCluster;
use AlphaRock\Core\Static\Underlying;

class MinuteBalanceImport
{
    public static function balanceForTimestamp(string $timestamp, int $n = 1)
    {
        Time::toFormat($timestamp, Time::MYSQL_MINUTE);
        if ($n > 1) {
            Log::debug("Balance import for timestamp {$timestamp} in Loop mode");
            Log::debug("n=$n");
        }

        for ($i = 1; $i <= $n; $i++) {
            if($timestamp > Time::now(Time::MYSQL_MINUTE, '-2 minute')){
                Log::info("Break Loop at timestamp {$timestamp}");
                break;
            }
            static::getBalances($timestamp, $i);
            $timestamp = Time::generate($timestamp, Time::MYSQL_MINUTE, '+1 minute');
        }
    }

    public static function getBalances(string $timestamp, int $i)
    {
        $tradingMonth = Time::generate($timestamp, Time::ISO_MONTH);
        $tradingWeek = Time::generate($timestamp, Time::ISO_WEEK);
        $tradingDay = Time::generate($timestamp, Time::MYSQL_DATE);
        $tradingHour = Time::generate($timestamp, Time::MYSQL_FULLHOUR);
        $tradingMin = Time::generate($timestamp, Time::MYSQL_MINUTE);
        $tradingMinNext = Time::generate($timestamp, Time::MYSQL_MINUTE, '+1 minute');
        $timeOfDay = Time::generate($timestamp, Time::TIME_MINUTE);
        $updatedTs = Time::now(Time::MYSQL_MILLISEC);

        $sql = <<<SQL
            WITH latest as
         (
             SELECT account_id, underlying_id, wallet, exposure, MAX(ts) AS ts
             FROM positions__underlyings
             WHERE ts < '$tradingMinNext'
             GROUP BY account_id, underlying_id, wallet, exposure
         )

            SELECT '$tradingMin' as ts,
                   pu.last_seen_ts,
                   pu.account_id,
                   a.exchange_id,
                   pu.underlying_id,
                   pu.margin_balance,
                   pu.wallet
            FROM latest l
            JOIN positions__underlyings pu USING (account_id, underlying_id, wallet, exposure, ts)
            JOIN accounts a ON pu.account_id=a.account_id
            WHERE abs(pu.margin_balance) > 0
              AND underlying_id > 0
        SQL;

        $result = BackendCluster::query($sql);
        $rowCount = $result->getRowCount();

        $insert = [];

        $total = 0;
        foreach ($result->fetchAll() as $row) {
            $fx = FxMinuteCache::getFxRate($row->ts, $row->underlying_id);
            $positionUsd = $row->margin_balance * $fx;
            $total += $positionUsd;
            $posType = match (Underlying::details($row->underlying_id)->type) {
                "fiat" => "fiat_usd",
                "stable_coin" => "fiat_usd",
                "crypto" => "crypto_usd",
                default => "crypto_usd"
            };
            $insert[$row->account_id] ??= [
                "trading_month" => $tradingMonth,
                "trading_week" => $tradingWeek,
                "trading_day" => $tradingDay,
                "trading_hour" => $tradingHour,
                "trading_minute" => $tradingMin,
                "time_of_day" => $timeOfDay,
                "exchange_id" => $row->exchange_id,
                "account_id" => $row->account_id,
                "balance_usd" => 0,
                "fiat_usd" => 0,
                "crypto_usd" => 0,
                "updated_ts" => $updatedTs
            ];
            $insert[$row->account_id]["balance_usd"] += $positionUsd;
            $insert[$row->account_id][$posType] += $positionUsd;
        }
        $total = round($total, 2);

        foreach (array_chunk(array_values($insert), 5000) as $chunk) {
            MonkeyCluster::query(
                "INSERT INTO performance.minute_exposure",
                $chunk,
                "ON CONFLICT(trading_minute, account_id) DO UPDATE SET
                    balance_usd = EXCLUDED.balance_usd,
                    fiat_usd = EXCLUDED.fiat_usd,
                    crypto_usd = EXCLUDED.crypto_usd,
                    updated_ts = EXCLUDED.updated_ts
                ",
            );
        }

        Log::info("[$i] $timestamp => $total $ ($rowCount positions)");
    }
}
