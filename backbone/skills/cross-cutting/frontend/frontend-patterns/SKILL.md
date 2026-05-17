<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: frontend-patterns
description: Frontend architecture patterns for React, Next.js, Angular, state management, component design, and UI best practices. Use when building or reviewing web frontends.
origin: ECC
---

# Frontend Architecture Patterns

Frontend architecture and best practices for modern web applications, derived from Separation of Concerns (SoC).

## When to Use
- Designing frontend application structure
- Choosing between MVC, components, or micro-frontends
- Deciding on state management approach
- Reviewing frontend code organization
- Scaling a growing frontend codebase

---

## Quick Reference

| Pattern | Best For | Complexity |
|---------|----------|------------|
| **Component Architecture** | Most modern apps | Low |
| **Dumb-Smart Components** | Teams > 3 people | Low |
| **State Management** | Shared data across app | Medium |
| **Modular Architecture** | Large feature-based apps | Medium |
| **Micro-Frontends** | Multiple teams, independent deploy | High |
| **Unidirectional Data Flow** | Predictable state changes | Low |

---

## Separation of Concerns (SoC)

The foundational principle behind all frontend architecture patterns:

> A concern is a set of information that affects the code. Separate your program into distinct sections, each addressing a separate concern.

**Example concerns in frontend:**
- **Presentation** — How it looks (HTML/JSX, CSS)
- **Data Handling** — How data is fetched, transformed, stored
- **Business Logic** — Rules, validations, calculations
- **Routing** — Navigation, URL management

**Without SoC:** One file handles UI, API calls, and business rules.
**With SoC:** Each concern has a dedicated place.

---

## 1. Component Architecture

Split UI into small, reusable, self-contained components.

### Structure

```
src/
├── components/
│   ├── Button/
│   │   ├── Button.tsx          # Component logic
│   │   ├── Button.module.css   # Styles
│   │   ├── Button.test.tsx     # Tests
│   │   └── index.ts            # Public export
│   └── BookList/
│       ├── BookList.tsx
│       ├── BookList.module.css
│       ├── BookList.test.tsx
│       └── index.ts
```

### Example

```tsx
// BookList.tsx — one component, all its code together
interface Book {
  id: string;
  title: string;
  author: string;
}

export function BookList({ books }: { books: Book[] }) {
  return (
    <ul className={styles.list}>
      {books.map(book => (
        <li key={book.id} className={styles.item}>
          <span className={styles.title}>{book.title}</span>
          <span className={styles.author}>{book.author}</span>
        </li>
      ))}
    </ul>
  );
}
```

**Benefits:**
- Reusable across the app
- Easy to test in isolation
- Clear ownership (one folder = one component)

---

## 2. Dumb (Presentational) vs Smart (Container) Components

Separate presentation from data flow.

| Type | Also Called | Knows About | Doesn't Know About |
|------|-------------|-------------|-------------------|
| **Dumb** | Presentational | Props, UI | State management, API |
| **Smart** | Container | State, API, business logic | UI details |

### Dumb Component — Pure Presentation

```tsx
// BookCard.tsx — only displays data, no side effects
interface BookCardProps {
  title: string;
  author: string;
  onSelect: (id: string) => void;
}

export function BookCard({ title, author, onSelect }: BookCardProps) {
  return (
    <div className="book-card" onClick={() => onSelect(title)}>
      <h3>{title}</h3>
      <p>{author}</p>
    </div>
  );
}
```

### Smart Component — Data & Logic

```tsx
// BookListContainer.tsx — fetches data, manages state
import { useState, useEffect } from 'react';
import { BookCard } from './BookCard';

export function BookListContainer() {
  const [books, setBooks] = useState<Book[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/books')
      .then(res => res.json())
      .then(data => { setBooks(data); setLoading(false); });
  }, []);

  const handleSelect = (id: string) => {
    // Business logic: navigate, open modal, etc.
    console.log('Selected:', id);
  };

  if (loading) return <Spinner />;

  return (
    <div>
      {books.map(book => (
        <BookCard
          key={book.id}
          title={book.title}
          author={book.author}
          onSelect={handleSelect}
        />
      ))}
    </div>
  );
}
```

**Benefits:**
- Dumb components are reusable, testable, framework-agnostic
- Smart components centralize data flow decisions
- Junior developers can safely modify UI without touching logic

---

## 3. State Management

As applications grow, not all state belongs in the backend. Frontend needs its own data layer.

### When You Need State Management

- Multiple components share the same data
- Data flows through many levels of props (prop drilling)
- Complex update logic (multiple actions affect same state)
- Need for time-travel debugging, undo/redo

### Patterns

#### Redux Pattern (Flux Architecture)

```
Action → Dispatcher → Reducer → Store → View
                  ↑___________________|
```

```typescript
// Action
interface AddTodoAction {
  type: 'ADD_TODO';
  payload: { text: string };
}

// Reducer — pure function, determines new state
function todoReducer(state: TodoState, action: AddTodoAction): TodoState {
  switch (action.type) {
    case 'ADD_TODO':
      return {
        ...state,
        todos: [...state.todos, { id: crypto.randomUUID(), text: action.payload.text }]
      };
    default:
      return state;
  }
}

// Store — holds state, dispatches actions
const store = createStore(todoReducer);

// View — subscribes to store, dispatches actions
function TodoApp() {
  const todos = useSelector(state => state.todos);
  const dispatch = useDispatch();

  return (
    <div>
      {todos.map(todo => <TodoItem key={todo.id} {...todo} />)}
      <button onClick={() => dispatch({ type: 'ADD_TODO', payload: { text: 'New' } })}>
        Add
      </button>
    </div>
  );
}
```

**Building blocks:**
- **Store** — Single source of truth for application state
- **Action** — Plain object describing what happened
- **Reducer** — Pure function that returns new state based on action
- **Selector** — Extracts derived data from state
- **Effect/Saga** — Handles side effects (API calls)

#### Modern Alternatives

| Library | Best For | Syntax |
|---------|----------|--------|
| **Zustand** | Simple global state | Minimal boilerplate |
| **Jotai** | Atomic state | Recoil-like, fine-grained |
| **Context + useReducer** | Built-in, no extra deps | React native |
| **TanStack Query** | Server state | Caching, deduping, syncing |

**Rule:** Use local state (`useState`) when possible. Elevate to global state only when truly shared.

---

## 4. Modular Architecture

Split application by domain/feature, not by technical layer.

### By Feature (Recommended)

```
src/
├── features/
│   ├── auth/
│   │   ├── components/         # LoginForm, RegisterForm
│   │   ├── hooks/              # useAuth, useLogin
│   │   ├── services/           # authApi.ts
│   │   ├── store/              # authSlice.ts (Redux)
│   │   └── types.ts            # Auth types
│   ├── products/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── services/
│   │   └── types.ts
│   └── cart/
│       ├── components/
│       ├── hooks/
│       └── services/
├── shared/
│   ├── components/             # Button, Input, Modal
│   ├── hooks/                  # useDebounce, useLocalStorage
│   └── utils/                  # formatCurrency, validateEmail
└── app/                        # App-level setup, routing
```

### Angular-Style Modules

```typescript
// products/products.module.ts
@NgModule({
  declarations: [ProductList, ProductDetail],
  imports: [CommonModule, RouterModule],
  providers: [ProductService],
  exports: [ProductList]
})
export class ProductsModule {}

// app.module.ts — gathers all modules
@NgModule({
  imports: [BrowserModule, AuthModule, ProductsModule, CartModule],
  bootstrap: [AppComponent]
})
export class AppModule {}
```

**Benefits:**
- Cohesive: everything for a feature is together
- Easy to extract to micro-frontend later
- Clear boundaries prevent spaghetti imports

---

## 5. Micro-Frontends

Extension of microservices to the frontend layer. Split a large app into independently deployable frontend pieces.

### When to Use

- Multiple teams own different parts of the UI
- Build times are unmanageable
- Different teams want different tech stacks
- Independent deployment cycles needed

### Integration Approaches

| Approach | How It Works | Trade-off |
|----------|-------------|-----------|
| **Build-time** | Import as npm packages | Tight coupling, shared build |
| **Run-time (iframe)** | Each MF in iframe | Full isolation, harder communication |
| **Run-time (Web Components)** | Each MF is a custom element | Good isolation, standard tech |
| **Run-time (Module Federation)** | Webpack/Vite shares modules at runtime | Most popular, flexible |

### Example: Module Federation (Vite)

```typescript
// host/vite.config.ts
export default defineConfig({
  plugins: [
    federation({
      remotes: {
        products: 'http://localhost:3001/assets/remoteEntry.js',
        cart: 'http://localhost:3002/assets/remoteEntry.js',
      },
      shared: ['react', 'react-dom']
    })
  ]
});

// host/App.tsx
const ProductList = lazy(() => import('products/ProductList'));
const CartWidget = lazy(() => import('cart/CartWidget'));

function App() {
  return (
    <div>
      <Header />
      <Suspense fallback={<Spinner />}>
        <ProductList />
        <CartWidget />
      </Suspense>
    </div>
  );
}
```

**Benefits:**
- Independent deployments
- Team autonomy
- Technology diversity

**Costs:**
- Complex build setup
- Shared dependency management
- Potential UI inconsistency

---

## 6. Unidirectional Data Flow

Data flows in one direction: toward the view. The view triggers actions that update state.

```
User Action → Update State → Re-render View → User Sees Change
                 ↑___________________________________|
```

### React Example

```tsx
function Counter() {
  const [count, setCount] = useState(0);  // State

  return (
    <div>
      <p>{count}</p>                        {/* View reads state */}
      <button onClick={() => setCount(count + 1)}>  {/* Action updates state */}
        Increment
      </button>
    </div>
  );
}
```

### Why Unidirectional?

- **Predictable** — State changes in one place
- **Debuggable** — Easy to trace data flow
- **Testable** — Pure reducers, deterministic output

### Contrast: Two-Way Binding

```html
<!-- Angular two-way binding -- less predictable at scale -->
<input [(ngModel)]="user.name">
<!-- Changing input updates model; changing model updates input -->
<!-- Hard to trace: who changed user.name? -->
```

**Recommendation:** Prefer unidirectional. Use two-way binding sparingly (forms are acceptable).

---

## 7. MVC, MVP, MVVM (Legacy Patterns)

Understanding where modern patterns came from:

| Pattern | Flow | Modern Equivalent |
|---------|------|-------------------|
| **MVC** | Model ↔ Controller → View | Server-side rendering |
| **MVP** | Model ↔ Presenter → View | Smart/Dumb components |
| **MVVM** | Model ↔ ViewModel ↔ View | React hooks, Vue computed |

**Modern frontend mostly uses:** Component architecture + state management + unidirectional flow.

---

## Decision Tree

```
Starting a new frontend project?
├── Single developer, simple app?
│   └── Component architecture + local state
├── Team > 3, shared data?
│   └── Component architecture + state management (Zustand/Redux)
├── Large app, many features?
│   └── Modular architecture by feature
├── Multiple teams, independent deploy?
│   └── Micro-frontends (Module Federation)
└── Heavy server data sync?
    └── TanStack Query + local state for UI-only
```

---

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Prop Drilling** | Passing props through 5+ layers | Context or state management |
| **God Component** | 500+ line component doing everything | Split into smart/dumb |
| **Tight Coupling** | Components import internals of others | Public API via index.ts |
| **State Everywhere** | Every component has useState | Elevate shared state |
| **CSS Chaos** | Global styles conflicting | CSS Modules, Tailwind, Styled Components |

---

## Related Skills

- **Component design** → Use `clean-code` for naming and function design in components
- **API integration** → Use `api-design` for frontend-backend contract design
- **Testing** → Use `test-quality` for component and integration testing
- **Performance** → Use performance optimization for bundle splitting and memoization

---

## Quick Checklist

- [ ] Components are small (< 150 lines)
- [ ] Dumb components don't know about APIs or state management
- [ ] State is colocated (closest to where it's used)
- [ ] Features are self-contained folders
- [ ] No prop drilling beyond 2-3 levels
- [ ] Styles are scoped to components
