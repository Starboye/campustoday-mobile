<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('CREATE TABLE IF NOT EXISTS api_refresh_tokens (
            id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id VARCHAR(20) NOT NULL,
            token_hash CHAR(64) NOT NULL,
            expires_at DATETIME NOT NULL,
            revoked TINYINT(1) NOT NULL DEFAULT 0,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_api_refresh_user (user_id),
            INDEX idx_api_refresh_hash (token_hash)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

        DB::statement('CREATE TABLE IF NOT EXISTS api_devices (
            id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id VARCHAR(20) NOT NULL,
            platform ENUM(\'ios\',\'android\') NOT NULL,
            fcm_token VARCHAR(512) DEFAULT NULL,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_api_device_user_platform (user_id, platform)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    }

    public function down(): void
    {
        DB::statement('DROP TABLE IF EXISTS api_devices');
        DB::statement('DROP TABLE IF EXISTS api_refresh_tokens');
    }
};
