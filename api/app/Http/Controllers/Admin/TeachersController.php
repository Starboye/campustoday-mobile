<?php

namespace App\Http\Controllers\Admin;

use App\Models\UserLogin;
use App\Services\Admin\CursorPaginator;
use App\Services\PasswordService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TeachersController extends AdminController
{
    public function __construct(
        CursorPaginator $cursor,
        private readonly PasswordService $passwords,
    ) {
        parent::__construct($cursor);
    }

    public function index(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['user_login'])) {
            return $response;
        }

        $query = DB::table('user_login')->where('access', 1);

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', '%'.$search.'%')
                    ->orWhere('id', 'like', '%'.$search.'%');
            });
        }

        $page = $this->cursor->paginate($query, $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => $this->formatTeacher($row))->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['user_login'])) {
            return $response;
        }

        $data = $request->validate([
            'username' => ['required', 'string', 'max:100'],
            'password' => ['required', 'string', 'min:6'],
            'name' => ['nullable', 'string', 'max:200'],
            'id' => ['nullable', 'string', 'max:20'],
        ]);

        if (UserLogin::query()->where('name', $data['username'])->exists()) {
            return response()->json(['message' => 'Username already exists.'], 422);
        }

        $id = $data['id'] ?? $this->nextTeacherId();

        if (UserLogin::query()->find($id)) {
            return response()->json(['message' => 'Teacher ID already exists.'], 422);
        }

        DB::table('user_login')->insert([
            'id' => $id,
            'name' => $data['username'],
            'password' => $this->passwords->hash($data['password']),
            'access' => 1,
        ]);

        return response()->json($this->formatTeacher((object) [
            'id' => $id,
            'name' => $data['username'],
            'display_name' => $data['name'] ?? $data['username'],
        ]), 201);
    }

    public function show(string $id): JsonResponse
    {
        if ($response = $this->requireTables(['user_login'])) {
            return $response;
        }

        $user = UserLogin::query()->find($id);
        if (! $user || (int) $user->access !== 1) {
            return response()->json(['message' => 'Teacher not found.'], 404);
        }

        return response()->json($this->formatTeacher((object) [
            'id' => $user->id,
            'name' => $user->name,
            'display_name' => $user->name,
        ]));
    }

    public function destroy(string $id): JsonResponse
    {
        if ($response = $this->requireTables(['user_login'])) {
            return $response;
        }

        $user = UserLogin::query()->find($id);
        if (! $user || (int) $user->access !== 1) {
            return response()->json(['message' => 'Teacher not found.'], 404);
        }

        DB::table('user_login')->where('id', $id)->delete();

        return response()->json(['message' => 'Teacher deleted.']);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        if ($response = $this->requireTables(['user_login'])) {
            return $response;
        }

        $user = UserLogin::query()->find($id);
        if (! $user || (int) $user->access !== 1) {
            return response()->json(['message' => 'Teacher not found.'], 404);
        }

        $data = $request->validate([
            'username' => ['sometimes', 'string', 'max:100'],
            'password' => ['sometimes', 'string', 'min:6'],
        ]);

        if (isset($data['username']) && UserLogin::query()
            ->where('name', $data['username'])
            ->where('id', '!=', $id)
            ->exists()) {
            return response()->json(['message' => 'Username already exists.'], 422);
        }

        $update = [];
        if (isset($data['username'])) {
            $update['name'] = $data['username'];
        }
        if (isset($data['password'])) {
            $update['password'] = $this->passwords->hash($data['password']);
        }

        if ($update !== []) {
            DB::table('user_login')->where('id', $id)->update($update);
        }

        $user->refresh();

        return response()->json($this->formatTeacher((object) [
            'id' => $user->id,
            'name' => $user->name,
            'display_name' => $user->name,
        ]));
    }

    private function formatTeacher(object $row): array
    {
        return [
            'id' => (string) $row->id,
            'username' => (string) $row->name,
            'display_name' => (string) ($row->display_name ?? $row->name),
        ];
    }

    private function nextTeacherId(): string
    {
        $max = DB::table('user_login')
            ->where('access', 1)
            ->selectRaw('MAX(CAST(id AS UNSIGNED)) as max_id')
            ->value('max_id');

        $next = ((int) $max) + 1;

        return 'T'.max($next, 1);
    }
}
