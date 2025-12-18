<?php
/**
 * Health Check Script for Bitrix Docker Container
 * Used by docker-compose healthcheck
 */

http_response_code(200);
header('Content-Type: text/plain; charset=utf-8');
header('Cache-Control: no-cache, no-store, must-revalidate');

echo 'OK';
