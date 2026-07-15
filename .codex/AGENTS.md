# Global development instructions

## Implementation

- Prefer simple, maintainable implementations.
- Preserve each project's existing architecture and conventions.
- Read the repository documentation before making changes.
- Prefer Go for backend and systems work when the repository does not already dictate another language.
- Prefer PostgreSQL for relational persistence.
- For web applications, follow the framework already used by the repository. Do not replace an existing frontend stack without a clear reason.
- Avoid unnecessary dependencies.

## Scope and verification

- Keep changes focused and reviewable.
- Do not make unrelated cleanup changes.
- Run relevant formatting, linting, tests, and builds before declaring work complete.
- Clearly report commands that failed or could not be run.

## Safety

- Ask before destructive operations, breaking API changes, database resets, force pushes, or broad dependency upgrades.
- Never commit secrets, credentials, `.env` files, access tokens, private keys, or generated local state.

## Tools

- Use `vi` as the preferred terminal editor when an editor must be selected.
