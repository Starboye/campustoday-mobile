<?php

return [
    'jwt_secret' => env('JWT_SECRET', env('APP_KEY')),
    'access_ttl' => (int) env('JWT_ACCESS_TTL', 1800),
    'refresh_ttl' => (int) env('JWT_REFRESH_TTL', 604800),
    'login_rate_limit' => (int) env('LOGIN_RATE_LIMIT', 10),
];
