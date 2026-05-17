# Laravel Conventions

*Laravel-specific patterns. See `php-conventions.md` for base PHP patterns.*

---

## Quick Reference

| Pattern | Laravel |
|---------|---------|
| Routes | `routes/web.php`, `routes/api.php` |
| Controller | `Controller` class |
| Model | Eloquent model |
| Repository | Custom implementation |
| Service | `Service` class |
| Form Request | `FormRequest` |
| Resource | `API Resource` |
| Migration | Migration file |

---

## RESTful Routes

```php
Route::resource('users', UserController::class);
```

Generates:
| Method | URI | Action |
|-------|-----|-------|
| GET | `/users` | `index` |
| GET | `/users/{user}` | `show` |
| GET | `/users/create` | `create` |
| POST | `/users` | `store` |
| GET | `/users/{user}/edit` | `edit` |
| PUT/PATCH | `/users/{user}` | `update` |
| DELETE | `/users/{user}` | `destroy` |

### API Routes

```php
Route::apiResource('users', UserController::class);
```

### Named Routes

```php
Route::get('/profile', [UserController::class, 'profile'])
    ->name('users.profile');
```

---

## Controllers

```php
<?php
declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Requests\User\CreateRequest;
use App\Http\Requests\User\UpdateRequest;
use App\Http\Resources\UserResource;
use App\Services\UserService;
use Illuminate\Http\JsonResponse;

class UserController extends Controller
{
    public function __construct(
        private UserService $service,
    ) {}
    
    public function index(): JsonResponse
    {
        return response()->json(
            UserResource::collection($this->service->getAll())
        );
    }
    
    public function store(CreateRequest $request): JsonResponse
    {
        $user = $this->service->create($request->toDTO());
        
        return response()->json(
            new UserResource($user),
            201
        );
    }
    
    public function show(string $id): JsonResponse
    {
        $user = $this->service->findById($id);
        
        return $user
            ? response()->json(new UserResource($user))
            : response()->json(['error' => 'Not found'], 404);
    }
    
    public function update(UpdateRequest $request, string $id): JsonResponse
    {
        $user = $this->service->update($id, $request->toDTO());
        
        return response()->json(new UserResource($user));
    }
    
    public function destroy(string $id): JsonResponse
    {
        $this->service->delete($id);
        
        return response()->json(null, 204);
    }
}
```

---

## Eloquent Models

```php
<?php
declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class User extends Model
{
    protected $fillable = ['name', 'email'];
    protected $hidden = ['password'];
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];
    
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
}
```

---

## Service Layer

```php
<?php
declare(strict_types=1);

namespace App\Services;

use App\DTOs\CreateUserDTO;
use App\Models\User;
use App\Repositories\UserRepository;
use Illuminate\Support\Facades\Hash;

class UserService
{
    public function __construct(
        private UserRepository $repository,
    ) {}
    
    public function create(CreateUserDTO $dto): User
    {
        $user = new User();
        $user->name = $dto->name;
        $user->email = $dto->email;
        $user->password = Hash::make($dto->password);
        
        $this->repository->save($user);
        
        return $user;
    }
}
```

---

## Form Requests

```php
<?php
declare(strict_types=1);

namespace App\Http\Requests\User;

use Illuminate\Foundation\Http\FormRequest;

class CreateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }
    
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'min:2'],
            'email' => ['required', 'email', 'unique:users'],
            'password' => ['required', 'string', 'min:8'],
        ];
    }
}
```

---

## API Resources

```php
<?php
declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
```

---

## Migrations

```php
<?php
declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();
        });
    }
    
    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
```

---

## Related

- `conventions-general.md` - Core principles
- `php-conventions.md` - PHP patterns

*Last updated: 2026-04-12*