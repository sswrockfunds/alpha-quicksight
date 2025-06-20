<?php

namespace AlphaRock\Alpha\QuickSight\Accounts;

use AlphaRock\Core\Account\AccountEntity;
use AlphaRock\Core\Account\AccountFactory;
use AlphaRock\Core\CoinMover\CoinMoverCapability;
use AlphaRock\Core\Common\Time;
use AlphaRock\Core\Static\Log;
use AlphaRock\Core\Static\MonkeyCluster;
use Exception;
use Shuchkin\SimpleXLSX;

class AccountImporter
{
    public const COLUMN_MAP = [];

    public const SKIP_COLUMNS = [
        "market", "exchange_id",
        "account_name", "account_uid", "account_identifier",
        "server", // Is retrieved from backend
    ];

    public const NORMALIZE_MAP = [
        // Strategy
        "AlphaFlexx", "AlphaFlexxHedge", "Maverick", "FundingTrader", "Hedge", "Sonic",
        // Account Type
        "Main", "Production", "IEO", "Activity", "Testing", "External",
        // Instrument Type
        "spot", "derivate", "multi",
        // Owner
        "AlphaRock", "CryptoStruct", "Timo", "Lukas", "Jonas", "Florian", "Marco"
    ];

    public const string DEFAULT_FILE = "/home/ubuntu/monkey-share/tradingVault/accountDetails_v3.xlsx";

    public static array $accounts = [];

    public static function import()
    {
        // 1. Get all accounts from CryptoStruct Backend
        AccountImporter::$accounts = AccountFactory::queryAccountsFromBackend();
        if (empty(AccountImporter::$accounts)) {
            Log::error("No accounts returned from backend – aborting import.");
            return [];
        }

        // 2. Enrich Account Data with Excel import
        AccountImporter::dataFromFile();
        if (empty(AccountImporter::$accounts)) {
            Log::error("No account data after enrichment – aborting import.");
            return [];
        }

        // 3. Generate Insert Arrays
        $current = [];
        $history = [];
        $day = Time::today();
        foreach (AccountImporter::$accounts as $account) {
            $row = AccountImporter::getInsertArray($account);
            $current[] = $row;
            $history[] = ["trading_day" => $day, ...$row];
        }

        # market, instrument_type

        // 4. Update DB
        MonkeyCluster::query("DELETE FROM account.history WHERE trading_day = ?", $day);
        MonkeyCluster::query("INSERT INTO account.history", $history);

        MonkeyCluster::query("DELETE FROM account.current");
        MonkeyCluster::query("INSERT INTO account.current", $current);

        return $history;
    }

    private static function readXlsx(string $file): array|false
    {
        Log::info("Reading File $file");
        $xlsx = SimpleXLSX::parse($file);

        if (!$xlsx) {
            throw new Exception("Could not read file");
        }

        $rows = $xlsx->rows();

        if (count($rows) < 100) {
            throw new Exception("Parsed XLSX is empty or only contains header.");
        }

        return $xlsx->rows();
    }

    private static function dataFromFile(): void
    {
        $file = self::DEFAULT_FILE;

        $sheetData = AccountImporter::readXlsx($file);

        $header = [];
        $accountIdCol = null;
        foreach (array_shift($sheetData) as $index => $colName) {
            $header[$index] = self::COLUMN_MAP[$colName] ?? $colName;
            if ($colName === "account_id") {
                $accountIdCol = $index;
            }
        }

        foreach ($sheetData as $row) {
            $accountId = (int)$row[$accountIdCol];
            foreach ($row as $colKey => $colValue) {
                $colName = $header[$colKey];
                $colValue = AccountImporter::normalizeValue($colValue);

                if (!in_array($colName, self::SKIP_COLUMNS)) {
                    AccountImporter::$accounts[$accountId]->{$colName} = $colValue;
                }
            }
            $coinMoverCapabilities = CoinMoverCapability::forExchangeId(AccountImporter::$accounts[$accountId]->exchange_id);
            AccountImporter::$accounts[$accountId]->coinmover = ($coinMoverCapabilities !== false);
            AccountImporter::$accounts[$accountId]->updated_ts = Time::now(Time::MYSQL_SEC);
        }
    }

    private static function getInsertArray(AccountEntity $dto, ?string $tradingDay = null): array
    {
        $array = $tradingDay !== null ? ["trading_day" => $tradingDay] : [];
        $array += [
            "account_id" => $dto->account_id,
            "main_account_id" => $dto->main_account_id,
            "account_name" => $dto->account_name,
            "account_uid" => $dto->account_uid,
            "account_identifier" => $dto->account_identifier,
            "active" => $dto->active,
            "exchange_id" => $dto->exchange_id,
            // "market" => $dto->market,
            "account_type" => $dto->account_type,
            "strategy" => $dto->strategy,
            "instrument_type" => $dto->instrument_type,
            "server" => $dto->server,
            "counter_underlying" => $dto->counter_underlying,
            "owner" => $dto->owner,
            "portfolio" => $dto->portfolio,
            "custody" => $dto->custody,
            "collateral" => $dto->collateral,
            "cap_distributor" => $dto->cap_distributer,
            "morpheus_check" => $dto->morpheus_check,
            "coinmover" => $dto->coinmover,
            "af_mode" => $dto->af_mode,
            "comment" => $dto->comment,
            "updated_ts" => $dto->updated_ts
        ];

        return $array;
    }

    private static function normalizeValue(mixed $value)
    {
        // parse bool and null
        $value = match (strtolower($value)) {
            "active", "yes" => true,
            "inactive", "no" => false,
            "empty" => null,
            default => $value
        };

        // normalize lower/upper case usage
        foreach (self::NORMALIZE_MAP as $normalizedValue) {
            if (strtolower($normalizedValue) === strtolower($value)) {
                return $normalizedValue;
            }
        }

        return $value;
    }
}
