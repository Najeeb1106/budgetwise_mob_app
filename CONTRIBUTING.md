# Contributing to BudgetWise

Thank you for your interest in contributing to BudgetWise! To maintain a professional codebase, please follow these guidelines.

## Branching Strategy

We follow a structured branching model. Never commit directly to `main` or `develop`.

- `main`: Production-ready code only. Always deployable and matching the App/Play Store builds.
- `develop`: Integration branch for features. This is the default target branch for Pull Requests.
- `feature/your-feature-name`: For adding new features or screens. Branch off `develop`.
- `fix/your-fix-name`: For resolving bugs. Branch off `develop` (or `main` for critical production hotfixes).

## Commit Messages

We enforce the **Conventional Commits** specification. Commit messages must be written in the imperative mood, lowercase, and follow this pattern:

```
<type>(<scope>): <short description>
```

### Allowed Types
- `feat`: A new feature (e.g. `feat(auth): add biometric login`)
- `fix`: A bug fix (e.g. `fix(home): resolve list view scroll lag`)
- `refactor`: Code changes that neither fix a bug nor add a feature
- `docs`: Documentation changes only (e.g. `docs(readme): add build steps`)
- `style`: Changes that do not affect the meaning of the code (formatting, white-space)
- `perf`: Code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process, auxiliary tools, or dependencies

## Code Quality Checklist

Before submitting a Pull Request, ensure that:
1. **Formatting**: Your code is formatted using `dart format .`.
2. **Analysis**: Static analysis passes with zero warnings or errors using `flutter analyze`.
3. **No Dead Code**: Commented-out code and debug print statements are removed.
4. **No Secrets**: No API keys, credentials, or keystores are hardcoded or committed.
5. **Testing**: All existing unit and widget tests pass, and you have added new tests for any core logic introduced.
