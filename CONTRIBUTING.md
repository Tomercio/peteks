# Contributing to Peteks

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Always mirrors the latest Play Store release. Merge here only when releasing. |
| `develop` | Active development. All feature branches merge into `develop` first. |
| `feature/*` | Individual features (e.g. `feature/folders`, `feature/premium-themes`). Branch from `develop`. |
| `hotfix/*` | Urgent production fixes. Branch from `main`, merge back to both `main` and `develop`. |

Every release on `main` is tagged `vX.Y.Z` (e.g. `v1.0.0`).

## Release Flow

1. Finish feature work on `develop`.
2. Run `./scripts/bump_version.sh minor` (or `patch` / `major`).
3. Open a PR: `develop` → `main`.
4. Merge and push the tag: `git push && git push --tags`.
5. GitHub Actions builds the APK + AAB and creates a GitHub Release automatically.

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add folder system
fix: grid view no longer capped at 9 notes
chore: bump version to 1.1.0+2
docs: update README with widget instructions
```

## Code Style

- Dart formatting: `dart format .`
- Linting: `flutter analyze`
- No warnings should be introduced with a PR.

## Testing

Run `flutter test` before opening a PR.
