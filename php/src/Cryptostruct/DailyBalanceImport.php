<?php

namespace AlphaRock\Alpha\QuickSight\Cryptostruct;

use AlphaRock\Core\Common\Time;
use AlphaRock\Core\Masterdata\FxDailyCache;
use AlphaRock\Core\Static\BackendCluster;
use AlphaRock\Core\Static\Log;
use AlphaRock\Core\Static\MonkeyCluster;
use AlphaRock\Core\Static\Underlying;

class DailyBalanceImport
{
    public static function balanceForDay(string $date, int $n = 1)
    {
        Time::toDate($date);
        if ($n > 1) {
            Log::debug("Balance import for {$date} in Loop mode");
            Log::debug("n=$n");
        }

        for ($i = 1; $i <= $n; $i++) {
            if ($date >= Time::today()) {
                Log::info("Break Loop at {$date}");
                break;
            }
            static::getDailyBalances($date);
            $date = Time::generate($date, Time::MYSQL_DATE, '+1 day');
        }
    }

    public static function getDailyBalances(string $date)
    {
        $tradingMonth = Time::generate($date, Time::ISO_MONTH);
        $tradingWeek = Time::generate($date, Time::ISO_WEEK);
        $tradingDay = Time::generate($date, Time::MYSQL_DATE);
        $tradingDayNext = Time::generate($date, Time::MYSQL_DATE, '+1 day');
        $yearNum = Time::generate($date, 'Y');
        $monthNum = Time::generate($date, 'm');
        $dayNum = Time::generate($date, 'd');
        $updatedTs = Time::now(Time::MYSQL_MILLISEC);

        $sql = <<<SQL
            SELECT pu.account_id,
               pu.underlying_id,
               pu.ts,
               pu.last_seen_ts,
               pu.margin_balance,
               pu.wallet,
               pu.exposure,
               COALESCE(pu.cash_balance, 0) cash_balance,
               pu.available_balance available_balance
          FROM positions__underlyings pu
          JOIN (
                SELECT max(ts) ts, account_id, wallet, exposure, underlying_id
                  FROM positions__underlyings
                 WHERE ts<='$tradingDayNext'
              GROUP BY account_id, underlying_id, wallet, exposure
          ) latest ON latest.ts=pu.ts
                  AND latest.account_id=pu.account_id
                  AND latest.underlying_id=pu.underlying_id
                  AND latest.wallet=pu.wallet
                  AND latest.exposure=pu.exposure
        SQL;

        $sqlArchive = <<<SQL
            SELECT pu.account_id,
               pu.underlying_id,
               pu.ts,
               pu.last_seen_ts,
               pu.amount as margin_balance
          FROM positions__underlyings_archive pu
          JOIN (
                SELECT max(ts) ts, account_id, underlying_id
                  FROM positions__underlyings_archive
                 WHERE ts<='$tradingDayNext'
              GROUP BY account_id, underlying_id
          ) latest ON latest.ts=pu.ts
                  AND latest.account_id=pu.account_id
                  AND latest.underlying_id=pu.underlying_id
        SQL;

        $result = BackendCluster::query($sql);
        $rowCount = $result->getRowCount();

        $insert = [];

        $total = 0;
        foreach ($result->fetchAll() as $row) {
            $fx = FxDailyCache::getFxRate($tradingDay, $row->underlying_id);
            if ($fx === null) {
               $fx=0;
               Log::debug("No Fx for $row->underlying_id in account $row->account_id");
            }

            $positionUsd = $row->margin_balance * $fx;
            $total += $positionUsd;
            $insert[$row->account_id] ??= [
                "trading_month" => $tradingMonth,
                "trading_week" => $tradingWeek,
                "trading_day" => $tradingDay,
                "year_num" => $yearNum,
                "month_num" => $monthNum,
                "day_num" => $dayNum,
                "account_id" => $row->account_id,
                "exposure_usd" => 0,
                "crypto_exposure_usd" => 0,
                "updated_ts" => $updatedTs
            ];
            $insert[$row->account_id]["exposure_usd"] += $positionUsd;
            if (!in_array(Underlying::details($row->underlying_id)->type, ["fiat", "stable_coin"])) {
                $insert[$row->account_id]["crypto_exposure_usd"] += $positionUsd;
            }
        }
        $total = round($total, 2);

        foreach (array_chunk(array_values($insert), 5000) as $chunk) {
            MonkeyCluster::query(
                "INSERT INTO performance.daily",
                $chunk,
                "ON CONFLICT(trading_day, account_id) DO UPDATE SET
                    exposure_usd = EXCLUDED.exposure_usd,
                    crypto_exposure_usd = EXCLUDED.crypto_exposure_usd,
                    updated_ts = EXCLUDED.updated_ts
                ",
            );
        }

        Log::debug("$date => $total $ ($rowCount positions)");
    }
}
