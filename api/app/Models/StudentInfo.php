<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentInfo extends Model
{
    public $timestamps = false;

    protected $table = 'student_info';

    protected $primaryKey = 'id';

    public $incrementing = false;

    protected $keyType = 'string';
}
