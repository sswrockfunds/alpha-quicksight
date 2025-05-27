<?php

use AlphaRock\Core\Cli\CliParser;
use AlphaRock\Core\Static\Log;
use AlphaRock\Core\Log\LogLevel;

require_once __DIR__ . "/../../vendor/autoload.php";

$Cli = new CliParser($argv);
Log::setLogLevel(match ($Cli->flagIsSet('debug')) {
    true => LogLevel::DEBUG,
    default => LogLevel::INFO,
});
