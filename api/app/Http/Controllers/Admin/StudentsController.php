<?php

namespace App\Http\Controllers\Admin;

use App\Models\UserLogin;
use App\Services\Admin\CursorPaginator;
use App\Services\PasswordService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StudentsController extends AdminController
{
    public function __construct(
        CursorPaginator $cursor,
        private readonly PasswordService $passwords,
    ) {
        parent::__construct($cursor);
    }

    public function index(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['student_info', 'user_login'])) {
            return $response;
        }

        $query = DB::table('student_info as s')
            ->join('user_login as u', 'u.id', '=', 's.id')
            ->where('u.access', 0)
            ->select([
                's.id', 's.name', 's.standard', 's.section', 'u.name as username',
            ]);

        if ($standard = $request->query('standard')) {
            $query->where('s.standard', (int) $standard);
        }
        if ($section = $request->query('section')) {
            $query->where('s.section', $section);
        }

        $page = $this->cursor->paginate($query, $request, 's.id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => $this->formatStudent($row))->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['student_info', 'user_login'])) {
            return $response;
        }

        $data = $request->validate([
            'username' => ['required', 'string', 'max:100'],
            'password' => ['required', 'string', 'min:6'],
            'name' => ['required', 'string', 'max:200'],
            'standard' => ['required', 'integer', 'min:1'],
            'section' => ['required', 'string', 'max:10'],
            'id' => ['nullable', 'string', 'max:20'],
        ]);

        if (UserLogin::query()->where('name', $data['username'])->exists()) {
            return response()->json(['message' => 'Username already exists.'], 422);
        }

        $id = $data['id'] ?? $this->nextStudentId();

        if (UserLogin::query()->find($id)) {
            return response()->json(['message' => 'Student ID already exists.'], 422);
        }

        DB::transaction(function () use ($data, $id) {
            DB::table('user_login')->insert([
                'id' => $id,
                'name' => $data['username'],
                'password' => $this->passwords->hash($data['password']),
                'access' => 0,
            ]);

            DB::table('student_info')->insert([
                'id' => $id,
                'name' => $data['name'],
                'standard' => $data['standard'],
                'section' => $data['section'],
            ]);
        });

        return response()->json($this->loadStudent($id), 201);
    }

    public function show(string $id): JsonResponse
    {
        if ($response = $this->requireTables(['student_info', 'user_login'])) {
            return $response;
        }

        $user = UserLogin::query()->find($id);
        if (! $user || (int) $user->access !== 0) {
            return response()->json(['message' => 'Student not found.'], 404);
        }

        return response()->json($this->loadStudent($id));
    }

    public function destroy(string $id): JsonResponse
    {
        if ($response = $this->requireTables(['student_info', 'user_login'])) {
            return $response;
        }

        $user = UserLogin::query()->find($id);
        if (! $user || (int) $user->access !== 0) {
            return response()->json(['message' => 'Student not found.'], 404);
        }

        DB::transaction(function () use ($id) {
            DB::table('student_info')->where('id', $id)->delete();
            DB::table('user_login')->where('id', $id)->delete();
        });

        return response()->json(['message' => 'Student deleted.']);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        if ($response = $this->requireTables(['student_info', 'user_login'])) {
            return $response;
        }

        $user = UserLogin::query()->find($id);
        if (! $user || (int) $user->access !== 0) {
            return response()->json(['message' => 'Student not found.'], 404);
        }

        $data = $request->validate([
            'username' => ['sometimes', 'string', 'max:100'],
            'password' => ['sometimes', 'string', 'min:6'],
            'name' => ['sometimes', 'string', 'max:200'],
            'standard' => ['sometimes', 'integer', 'min:1'],
            'section' => ['sometimes', 'string', 'max:10'],
        ]);

        if (isset($data['username']) && UserLogin::query()
            ->where('name', $data['username'])
            ->where('id', '!=', $id)
            ->exists()) {
            return response()->json(['message' => 'Username already exists.'], 422);
        }

        DB::transaction(function () use ($data, $id) {
            $userUpdate = [];
            if (isset($data['username'])) {
                $userUpdate['name'] = $data['username'];
            }
            if (isset($data['password'])) {
                $userUpdate['password'] = $this->passwords->hash($data['password']);
            }
            if ($userUpdate !== []) {
                DB::table('user_login')->where('id', $id)->update($userUpdate);
            }

            $infoUpdate = array_filter([
                'name' => $data['name'] ?? null,
                'standard' => $data['standard'] ?? null,
                'section' => $data['section'] ?? null,
            ], fn ($v) => $v !== null);

            if ($infoUpdate !== []) {
                DB::table('student_info')->where('id', $id)->update($infoUpdate);
            }
        });

        return response()->json($this->loadStudent($id));
    }

    private function loadStudent(string $id): array
    {
        $row = DB::table('student_info as s')
            ->join('user_login as u', 'u.id', '=', 's.id')
            ->where('s.id', $id)
            ->first(['s.id', 's.name', 's.standard', 's.section', 'u.name as username']);

        return $this->formatStudent($row);
    }

    private function formatStudent(object $row): array
    {
        return [
            'id' => (string) $row->id,
            'name' => (string) $row->name,
            'username' => (string) $row->username,
            'standard' => $row->standard !== null ? (int) $row->standard : null,
            'section' => $row->section !== null ? (string) $row->section : null,
        ];
    }

    private function nextStudentId(): string
    {
        $max = DB::table('student_info')
            ->selectRaw('MAX(CAST(id AS UNSIGNED)) as max_id')
            ->value('max_id');

        $next = ((int) $max) + 1;

        return (string) max($next, 1000);
    }
}
