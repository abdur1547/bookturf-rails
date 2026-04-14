# Angular Web Frontend Context

## Overview

This document captures the current state, architecture, and recommended conventions for the Angular app located in `/web`.

The frontend is built as an Angular SPA using:
- Angular 21
- Tailwind CSS 4
- `@angular/cli` build system
- Prettier + `prettier-plugin-tailwindcss`
- ESLint via `@angular-eslint`
- Playwright for E2E tests

The app is currently a UI starter kit derived from `angular-tailwind`. It does not yet contain a complete Rails API integration layer.

## Current state

- The app is structured as a feature-driven Angular application.
- Routing is lazy-loaded via Angular modules.
- There is no dedicated Rails API adapter yet.
- A placeholder HTTP request exists in `src/app/modules/uikit/pages/table/table.component.ts` to `https://freetestapi.com/api/v1/users?limit=8`.
- `src/environments/environment.ts` and `src/environments/environment.prod.ts` only contain `production` flags.

## Entry points

- `web/src/main.ts` — application bootstrap.
- `web/src/index.html` — HTML shell.
- `web/src/styles.css` — global styles.
- `web/angular.json` — build, serve, and configuration.
- `web/package.json` — scripts and dependencies.

## Folder layout

### `web/src/app`

- `app-routing.module.ts` — root routing.
- `app.component.*` — root application shell.
- `core/` — application-wide singletons and core utilities.
- `shared/` — reusable shared components, directives, pipes, validators, models, and utilities.
- `modules/` — feature modules and page-level grouping.

### `core/`

Use this area for app-wide concerns:
- global constants and menu definitions
- guards
- interceptors
- global models
- singleton services that span the entire app

Current core contents:
- `core/constants/menu.ts`
- `core/models/menu.model.ts`
- `core/models/theme.model.ts`
- `core/services/theme.service.ts`

### `shared/`

Use `shared/` for reusable building blocks and cross-feature utilities.

Current shared contents:
- `shared/components/` — reusable UI components such as buttons and responsive helpers.
- `shared/directives/click-outside.directive.ts`
- `shared/dummy/user.dummy.ts`
- `shared/models/chart-options.ts`
- `shared/services/api-base.service.ts` — generic CRUD base service for API clients.
- `shared/utils/ckassnames.ts`
- `shared/validators/` — validator utilities.

### `modules/`

Feature modules should own pages, feature-specific components, routing, and any feature-scoped services.

Current features:
- `auth/` — auth pages and auth routing.
- `dashboard/` — dashboard UI, feature models, charts, and page components.
- `error/` — error pages and routing.
- `layout/` — application layout and navigation.
- `uikit/` — UI kit pages and component examples.

## Routing and lazy loading

Root app routing uses lazy loading:
- `''` → `LayoutModule`
- `auth` → `AuthModule`
- `errors` → `ErrorModule`
- `**` → redirect to `errors/404`

`LayoutModule` then lazy-loads child features:
- `dashboard`
- `components`

This means feature modules are loaded only when the corresponding route is visited.

## HTTP and API integration

Current HTTP setup:
- Several feature modules provide `HttpClient` via `provideHttpClient(withInterceptorsFromDi())`.
- No Rails backend API service exists yet.
- `src/app/modules/uikit/pages/table/table.component.ts` uses a direct `HttpClient.get()` call to an external demo API.

Recommended API integration pattern:

1. Add API base URLs to environment files:
   - `src/environments/environment.ts`
   - `src/environments/environment.prod.ts`
   - Example: `apiBaseUrl: 'https://api.example.com'`

2. Create shared API services under `src/app/shared/services/`:
   - `api-base.service.ts` — generic CRUD base service for typed API clients.
   - `auth.service.ts` — auth/sign-in, token storage, refresh.
   - `user.service.ts`, `booking.service.ts`, etc. for domain APIs.

3. Extend `ApiBaseService<T>` in feature-specific or domain services to keep requests dry and centralized.
   - Example: `class BookingService extends ApiBaseService<Booking> {}`
   - This helps keep HTTP methods, URL handling, and error handling consistent.

4. Use `HttpInterceptor` to attach auth tokens and handle API errors.
   - Keep interceptor logic in `core/interceptor/`.

4. Keep request/response DTOs in `shared/models/` for cross-feature use.
   - Feature-specific models may remain in `modules/<feature>/models/`.

5. Avoid component-level direct HTTP calls when an API service is appropriate.

## Styling and UI conventions

### Tailwind + CSS

- The app uses Tailwind CSS with PostCSS.
- Global styles live in `src/styles.css`.
- Component styles remain in component-specific `.css` files.
- Use Tailwind utility classes in templates and keep component CSS for styling that cannot be expressed in Tailwind.

### Prettier

The project uses `.prettierrc` with the following core settings:
- `useTabs: false`
- `tabWidth: 2`
- `singleQuote: true`
- `trailingComma: 'all'`
- `printWidth: 120`
- `bracketSameLine: true`

Scripts:
- `npm run prettier` — format source files.
- `npm run prettier:verify` — check formatting.
- `npm run prettier:staged` — format staged changes.

### ESLint

The app uses `@angular-eslint` with Angular recommended rules plus Prettier.

Key selector rules:
- Component selectors: `app-<name>` and `kebab-case`
- Directive selectors: `[app<DirectiveName>]` and `camelCase`

### Editor config

Editor settings are declared in `.editorconfig`:
- UTF-8 charset
- spaces, 2-space indent
- insert final newline
- trim trailing whitespace
- single quotes for `.ts`

## Code organization style

### Feature modules

Each feature should include:
- `feature.module.ts`
- `feature-routing.module.ts`
- `feature.component.ts/html/css`
- `pages/` for route-level page components
- `components/` for feature-specific reusable components
- `models/` for types used only by that feature

### Shared / reusable code

Keep generic UI abstractions in `shared/`, not in feature modules.

Examples:
- buttons, helpers, directives, pipes, validators
- utility functions like class name merging
- shared model definitions and helper types

### Core services and guards

Use `core/` for:
- global guards
- interceptors
- application-wide services
- centralized theming/menu definitions

### Naming and style

- Use `PascalCase` for component, directive, pipe, and service class names.
- Use `kebab-case` for file names and component selectors.
- Keep classes small and single-purpose.
- Prefer `OnPush` change detection if the app grows, but keep current default behavior unless performance demands change.

## Recommended conventions for Rails API integration

- Use a shared API service layer instead of calling Rails endpoints from page components.
- Keep API URLs in environment configuration.
- Use typed interfaces for API payloads.
- Represent Rails JSON responses with explicit models.
- Implement auth token handling with an interceptor and local/session storage.
- Keep error handling centralized in shared services or interceptors.

## Scripts and developer workflow

Primary commands:
- `npm start` — start dev server
- `npm run build` — build production bundle
- `npm run watch` — development build watch
- `npm run lint` — run ESLint
- `npm run test:e2e` — run Playwright E2E tests

## Notes for future usage

- The frontend is currently a UI shell and starter kit.
- The Rails backend should be connected via a dedicated service layer and environment-driven API base URL.
- The app already uses Angular lazy-loaded modules, which is a good foundation for scaling.
- Add additional shared utilities and a proper interceptor once the API contract is defined.
- Preserve the existing structure: `core/` for app-level concerns, `shared/` for reusable elements, `modules/` for feature boundaries.
