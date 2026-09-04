<?php

namespace App\Services;

class PasswordService
{
    public function isHashed(string $stored): bool
    {
        return str_starts_with($stored, '$2y$')
            || str_starts_with($stored, '$2a$')
            || str_starts_with($stored, '$argon2');
    }

    public function hash(string $plain): string
    {
        return password_hash($plain, PASSWORD_DEFAULT);
    }

    public function verify(string $plain, string $stored): bool
    {
        if ($stored === '') {
            return false;
        }

        if ($this->isHashed($stored)) {
            return password_verify($plain, $stored);
        }

        return hash_equals($stored, $plain);
    }

    public function rehashIfNeeded(string $plain, string $stored): ?string
    {
        if ($this->isHashed($stored)) {
            return null;
        }

        return $this->hash($plain);
    }
}
