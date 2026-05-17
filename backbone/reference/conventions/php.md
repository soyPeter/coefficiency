# PHP Conventions

*PHP-specific patterns and best practices. For base principles, see `conventions-general.md`.*

---

## PSR Standards

This project follows PHP-FIG PSR standards:

| PSR | Description |
|-----|-------------|
| PSR-12 | Coding Style Guide |
| PSR-4 | Autoloading |
| PSR-3 | Logging |
| PSR-7 | HTTP Messages |
| PSR-11 | Container Interface |

---

## Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| Classes | PascalCase | `UserService`, `OrderRepository` |
| Interfaces | PascalCase | `UserRepositoryInterface` |
| Traits | PascalCase | `TimestampableTrait` |
| Methods | camelCase | `findById()`, `calculateTotal()` |
| Variables | camelCase | `$userName`, `$orderTotal` |
| Constants | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Files | PascalCase | `UserService.php` |
| Config | kebab-case | `app-settings.php` |

---

## Namespace Structure

```php
<?php
declare(strict_types=1);

namespace App\Service;
```

### Recommended Structure

```
src/
├── Controller/
├── Service/
├── Repository/
├── Model/
├── DTO/
├── Event/
├── Exception/
└── Contract/
```

---

## Clean Code in PHP

### Naming

```php
// BAD
$u = $r->get();
$d = $req['d'];
$arr = [];

// GOOD
$user = $repository->findById($request->getId());
$orderData = $request->all();
$errors = [];
```

### Early Returns

```php
// BAD - Nested conditionals
public function getUser(string $id): ?User
{
    if ($id) {
        if ($this->repository) {
            $user = $this->repository->find($id);
            if ($user) {
                return $user;
            }
        }
    }
    return null;
}

// GOOD - Early returns
public function getUser(string $id): ?User
{
    if (!$id) {
        return null;
    }
    
    $user = $this->repository->find($id);
    
    if (!$user) {
        return null;
    }
    
    return $user;
}
```

---

## Type Safety

### Strict Types

```php
<?php
declare(strict_types=1);
```

### Return Types

```php
// Always use return types
public function findById(string $id): ?User
{
    // ...
}

public function getUsers(): array
{
    // ...
}

public function process(callable $callback): void
{
    $callback();
}
```

### PHP 8+ Features

```php
// Named arguments
$user = $userRepository->find(
    id: $id,
    includeRelations: true
);

// Match expression
$status = match ($type) {
    'active' => UserStatus::ACTIVE,
    'inactive' => UserStatus::INACTIVE,
    default => UserStatus::UNKNOWN,
};

// Nullsafe operator
$country = $user->getAddress()?->getCountry();

// Constructor property promotion
class User
{
    public function __construct(
        private string $name,
        private ?string $email = null,
    ) {}
}
```

---

## Dependency Injection

### Constructor Injection

```php
class UserService
{
    public function __construct(
        private UserRepository $repository,
        private ?LoggerInterface $logger = null,
    ) {}
}
```

### Interface Binding

```php
// In a service provider
$this->app->bind(
    UserRepositoryInterface::class,
    UserRepository::class
);
```

---

## Service Layer Pattern

```php
<?php
declare(strict_types=1);

namespace App\Service;

use App\Repository\UserRepository;
use App\DTO\CreateUserRequest;
use App\Model\User;

class UserService
{
    public function __construct(
        private UserRepository $repository,
    ) {}
    
    public function create(CreateUserRequest $request): User
    {
        $user = new User(
            name: $request->getName(),
            email: $request->getEmail(),
        );
        
        $this->repository->save($user);
        
        return $user;
    }
    
    public function findById(string $id): ?User
    {
        return $this->repository->find($id);
    }
}
```

---

## Repository Pattern

```php
<?php
declare(strict_types=1);

namespace App\Repository;

use App\Model\User;
use Illuminate\Support\Collection;

class UserRepository
{
    public function find(string $id): ?User
    {
        return User::find($id);
    }
    
    public function findByEmail(string $email): ?User
    {
        return User::where('email', $email)->first();
    }
    
    public function all(): Collection
    {
        return User::all();
    }
    
    public function save(User $user): void
    {
        $user->save();
    }
}
```

---

## Error Handling

```php
try {
    $this->service->process($data);
} catch (ValidationException $e) {
    return response()->json([
        'error' => 'Validation failed',
        'messages' => $e->getErrors(),
    ], 422);
} catch (RuntimeException $e) {
    Log::error('Processing failed', [
        'exception' => $e,
    ]);
    
    return response()->json([
        'error' => 'An error occurred',
    ], 500);
}
```

---

## Testing

```php
<?php
namespace Tests\Unit\Service;

use Tests\TestCase;
use App\Service\UserService;
use App\Repository\UserRepository;
use Mockery;

class UserServiceTest extends TestCase
{
    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }
    
    public function testShouldCreateUser(): void
    {
        $repository = Mockery::mock(UserRepository::class);
        $service = new UserService($repository);
        
        $repository->shouldReceive('save')
            ->once()
            ->andReturnUsing(function ($user) {
                $user->id = '1';
            });
        
        $user = $service->create($this->validRequest());
        
        $this->assertNotNull($user->id);
    }
}
```

---

## PHPStan & Psalm

Use static analysis tools:

```bash
# PHPStan
vendor/bin/phpstan analyse

# Psalm
vendor/bin/psalm
```

### Baseline

```xml
<!-- psalm.xml -->
<?xml version="1.0"?>
<psalm>
    <projectRoot>./src</projectRoot>
    <baseline path="./psalm-baseline.xml"/>
</psalm>
```

---

## Related

- `conventions-general.md` - Core principles
- `laravel-conventions.md` - Laravel-specific patterns

*Last updated: 2026-04-12*