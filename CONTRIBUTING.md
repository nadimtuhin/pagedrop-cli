# Contributing to pagedrop-cli

Thank you for your interest in contributing!

## Reporting Bugs

Open a GitHub issue. Include your OS, shell version, the command you ran, and the
output you got. The more detail, the faster it gets fixed.

## Submitting a Pull Request

1. Fork the repository.
2. Create a feature or fix branch off `main`:
   ```
   git checkout -b my-fix
   ```
3. Make your changes directly in the `pagedrop` shell script — there is no build step.
4. Syntax-check your work before committing:
   ```
   bash -n pagedrop
   ```
5. Push your branch and open a PR against `main`.

## Requirements

- bash
- curl
- jq **or** python3 (used for JSON parsing)

## Code Style

Keep it plain POSIX-compatible bash where possible. No external dependencies
beyond those listed above.
