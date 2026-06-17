<?php
/**
 * Диагностический скрипт теста почты для консоли Битрикс
 * Копировать в: /bitrix/admin/php_command_line.php
 *
 * Включает полную диагностику ошибок (обходит ограничения консоли Битрикс)
 */

// === СКОПИРУЙТЕ КОД НИЖЕ В КОНСОЛЬ ===

set_error_handler(function($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

try {
    $to = 'test@localhost';
    $from = 'noreply@localhost';
    $host = 'mailpit';
    $port = 1025;

    echo "<h3>Тест почты</h3><pre>";

    echo "1. SMTP ($host:$port)... ";
    $fp = fsockopen($host, $port, $errno, $errstr, 5);
    if ($fp) { echo "<b style='color:green'>OK</b>\n"; fclose($fp); }
    else { echo "<b style='color:red'>FAIL: $errstr</b>\n"; }

    echo "2. mail()... ";
    $ok = mail($to, 'Test ' . date('H:i:s'), 'Test message', "From: $from");
    echo $ok ? "<b style='color:green'>OK</b>\n" : "<b style='color:red'>FAIL</b>\n";

    echo "3. Bitrix Mail... ";
    if (class_exists('\Bitrix\Main\Mail\Mail')) {
        $ok = \Bitrix\Main\Mail\Mail::send([
            'TO' => $to,
            'SUBJECT' => 'Test Bitrix ' . date('H:i:s'),
            'BODY' => 'Test from Bitrix Mail API',
            'HEADER' => ['From' => $from]
        ]);
        echo $ok ? "<b style='color:green'>OK</b>\n" : "<b style='color:red'>FAIL</b>\n";
    } else {
        echo "<b style='color:orange'>Class not found</b>\n";
    }

    echo "</pre>";
    echo "<p><b>Mailpit:</b> <a href='http://localhost:8025' target='_blank'>http://localhost:8025</a></p>";

} catch (Throwable $e) {
    echo "<pre style='background:#fee;padding:10px;border:1px solid #c00;'>";
    echo "<b style='color:red;font-size:14px;'>ОШИБКА: " . get_class($e) . "</b>\n\n";
    echo "<b>Сообщение:</b> " . htmlspecialchars($e->getMessage()) . "\n";
    echo "<b>Файл:</b> " . htmlspecialchars($e->getFile()) . "\n";
    echo "<b>Строка:</b> " . $e->getLine() . "\n\n";
    echo "<b>Stack trace:</b>\n" . htmlspecialchars($e->getTraceAsString());
    echo "</pre>";
}

restore_error_handler();

// === КОНЕЦ СКРИПТА ===
