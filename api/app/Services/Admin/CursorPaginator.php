<?php

namespace App\Services\Admin;

use Illuminate\Database\Query\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class CursorPaginator
{
    /**
     * @return array{items: Collection, next_cursor: string|null}
     */
    public function paginate(Builder $query, Request $request, string $orderColumn = 'id'): array
    {
        $limit = min(max((int) $request->query('limit', 50), 1), 100);
        $cursor = $request->query('cursor');

        if ($cursor !== null && $cursor !== '') {
            $query->where($orderColumn, '>', $cursor);
        }

        $rows = $query->orderBy($orderColumn)->limit($limit + 1)->get();
        $hasMore = $rows->count() > $limit;

        if ($hasMore) {
            $rows = $rows->slice(0, $limit)->values();
        }

        $nextCursor = $hasMore && $rows->isNotEmpty()
            ? (string) $rows->last()->{$orderColumn}
            : null;

        return [
            'items' => $rows,
            'next_cursor' => $nextCursor,
        ];
    }
}
