<?php
declare(strict_types=1);

// Проверяем ограничения PHP из архива и перечисляем stable-релизы PECL.
function nodes(SimpleXMLElement $xml, string $path): array
{
    return $xml->xpath($path) ?: [];
}

function value(SimpleXMLElement $xml, string $path): string
{
    return trim((string) (nodes($xml, $path)[0] ?? ''));
}

try {
    if ($argc < 3) {
        throw new RuntimeException('Укажите check <package.xml> <пакет> [PHP] или releases <allreleases.xml>');
    }
    libxml_use_internal_errors(true);
    $xml = simplexml_load_file($argv[2], SimpleXMLElement::class, LIBXML_NONET);
    if ($xml === false) {
        throw new RuntimeException('Не удалось прочитать XML-метаданные PECL');
    }
    if ($argv[1] === 'releases') {
        $versions = [];
        foreach (nodes($xml, '/*[local-name()="a"]/*[local-name()="r"]') as $release) {
            $version = value($release, './*[local-name()="v"]');
            if (value($release, './*[local-name()="s"]') === 'stable'
                && preg_match('/^[0-9][0-9A-Za-z.+-]*$/D', $version)) {
                $versions[] = $version;
            }
        }
        $versions = array_unique($versions);
        usort($versions, static fn(string $a, string $b): int => version_compare($b, $a));
        if (!$versions) {
            throw new RuntimeException('В ответе PECL нет stable-релизов');
        }
        echo implode("\n", $versions) . "\n";
        exit(0);
    }
    if ($argv[1] !== 'check' || $argc < 4) {
        throw new RuntimeException('Некорректная команда проверки PECL');
    }
    $name = value($xml, './*[local-name()="name"]');
    $version = value($xml, './*[local-name()="version"]/*[local-name()="release"]');
    $state = value($xml, './*[local-name()="stability"]/*[local-name()="release"]');
    // Старые архивы могут содержать package.xml формата 1.0.
    if ($version === '') {
        $version = value($xml, './*[local-name()="release"]/*[local-name()="version"]');
        $state = value($xml, './*[local-name()="release"]/*[local-name()="state"]');
    }
    if (strcasecmp($name, $argv[3]) !== 0 || $state !== 'stable'
        || !preg_match('/^[0-9][0-9A-Za-z.+-]*$/D', $version)) {
        throw new RuntimeException('Архив не содержит ожидаемый stable-релиз PECL');
    }
    $php = $argv[4] ?? PHP_VERSION;
    $compatible = true;
    foreach (nodes($xml, './*[local-name()="dependencies"]/*[local-name()="required"]/*[local-name()="php"]') as $dependency) {
        $min = value($dependency, './*[local-name()="min"]');
        $max = value($dependency, './*[local-name()="max"]');
        if (($min !== '' && version_compare($php, $min, '<'))
            || ($max !== '' && version_compare($php, $max, '>'))) {
            $compatible = false;
        }
        foreach (nodes($dependency, './*[local-name()="exclude"]') as $exclude) {
            if (version_compare($php, trim((string) $exclude), '==')) {
                $compatible = false;
            }
        }
    }
    $operators = ['ge' => '>=', 'gt' => '>', 'le' => '<=', 'lt' => '<', 'eq' => '==', 'ne' => '!='];
    foreach (nodes($xml, './*[local-name()="release"]/*[local-name()="deps"]/*[local-name()="dep"][@type="php"]') as $dependency) {
        $relation = (string) $dependency['rel'];
        if ($relation !== 'has') {
            if (!isset($operators[$relation])) {
                throw new RuntimeException('Неизвестное ограничение PHP в package.xml');
            }
            if (!version_compare($php, (string) $dependency['version'], $operators[$relation])) {
                $compatible = false;
            }
        }
    }
    echo $version;
    if (!$compatible) {
        file_put_contents('php://stderr', "PECL: $name $version не поддерживает PHP $php\n");
        exit(1);
    }
} catch (Throwable $error) {
    file_put_contents('php://stderr', $error->getMessage() . "\n");
    exit(2);
}
