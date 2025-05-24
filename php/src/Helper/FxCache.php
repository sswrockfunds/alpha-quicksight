<?php

namespace AlphaRock\Alpha\QuickSight\Helper;

use AlphaRock\Core\Common\Time;
use AlphaRock\Core\Static\Log;
use AlphaRock\Core\Static\MonkeyCluster;

class FxCache
{
    public static string $lookAhead = '30 minutes';
    public static array $cache = [];

    public static function getFxRate(string $timestamp, int $underlyingId): float
    {
        Time::toFormat($timestamp, Time::MYSQL_MINUTE);

        if(!array_key_exists($timestamp, self::$cache)) {
            static::queryFxRates($timestamp);
        }

        return self::$cache[$timestamp][$underlyingId] ?? 0;
    }

    private static function queryFxRates(string $sinceTimestamp): void
    {
        Time::toFormat($sinceTimestamp, Time::MYSQL_MINUTE);

        Log::debug("Querying fx rates for $sinceTimestamp");
        static::$cache = [
            $sinceTimestamp => []
        ];
        $lookahead = static::$lookAhead;
        $sql = <<<SQL
            SELECT ts::timestamp, underlying_id, fx
              FROM cryptostruct.fx_minute
             WHERE ts >='$sinceTimestamp'
               AND ts<('$sinceTimestamp'::timestamp + Interval '$lookahead')
        SQL;

        foreach (MonkeyCluster::fetchAll($sql) as $row) {
            $ts = (string)$row->ts;
            Time::toFormat($ts, Time::MYSQL_MINUTE);
            static::$cache[$ts] ??= [];
            static::$cache[$ts][$row->underlying_id] = $row->fx;
        }
    }

}
