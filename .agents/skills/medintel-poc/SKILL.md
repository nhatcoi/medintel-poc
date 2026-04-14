```markdown
# medintel-poc Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill introduces the core development patterns and workflows used in the `medintel-poc` Swift codebase. It covers naming conventions, import/export styles, commit patterns, and the main workflow for enhancing features with UI and tests. By following these guidelines, contributors can ensure consistency and maintainability across the project.

## Coding Conventions

### File Naming
- Use **snake_case** for all file names.
  - Example: `patient_profile.swift`, `user_repository.swift`

### Import Style
- Use **relative imports** within the codebase.
  - Example:
    ```swift
    import "../models/user_model"
    ```

### Export Style
- Use **named exports** to expose specific functions, classes, or structs.
  - Example:
    ```swift
    public struct PatientProfile { ... }
    ```

### Commit Patterns
- Follow **conventional commit** style.
- Use the `feat` prefix for new features or enhancements.
- Commit messages average 76 characters.
  - Example:
    ```
    feat: add patient profile UI and validation logic
    ```

## Workflows

### Feature Enhancement with UI and Tests
**Trigger:** When you want to add or improve a feature, including UI, data, and validation logic, and ensure it is tested.  
**Command:** `/enhance-feature`

1. Update or add Swift files in `lib/features/<feature>` for UI and logic changes.
    - Example: `lib/features/appointments/appointment_screen.swift`
2. Update data models and repositories in `lib/features/<feature>/data/`.
    - Example: `lib/features/appointments/data/appointment_repository.swift`
3. Update or add widgets in `lib/features/<feature>/widgets/`.
    - Example: `lib/features/appointments/widgets/appointment_card.swift`
4. Update constants or theme files if needed.
    - Example: `lib/core/constants/colors.swift`
5. Update or add tests in `test/` related to the feature.
    - Example: `test/appointments_test.swift`
6. Update documentation in `README.md` if relevant.

**Example Directory Structure:**
```
client-med/
  lib/
    features/
      appointments/
        appointment_screen.swift
        data/
          appointment_repository.swift
        widgets/
          appointment_card.swift
    core/
      constants/
        colors.swift
      theme/
        theme_config.swift
  test/
    appointments_test.swift
  README.md
```

## Testing Patterns

- Test files use the pattern `*.test.*` (e.g., `appointments_test.swift`).
- The testing framework is currently **unknown**; follow the existing test structure.
- Place tests in the `test/` directory, mirroring the feature structure.
- Example test file:
    ```swift
    import "../lib/features/appointments/appointment_screen"

    // Example test case
    func testAppointmentCreation() {
        // Test logic here
    }
    ```

## Commands

| Command           | Purpose                                                        |
|-------------------|----------------------------------------------------------------|
| /enhance-feature  | Start the feature enhancement workflow with UI and tests       |
```