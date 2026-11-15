# Contributing to Appendix

Thank you for your interest in contributing to **Appendix**! As an open-source, privacy-focused offline writing assistant, community contributions help make this tool better for everyone.

## Getting Started

1. Fork the repository and create your feature branch:
   ```bash
   git checkout -b feature/my-new-feature
   ```
2. Ensure you have the required prerequisites:
   - Flutter SDK (`flutter doctor` should be clean)
   - Rust toolchain (`rustc --version`, `cargo --version`)
3. Make your changes following the architectural principles:
   - **Privacy First**: Never add cloud dependencies, external telemetry, or un-consented network calls.
   - **Performance**: Grammar analysis must remain under 10ms for real-time keystroke responsiveness.
   - **Modularity**: Business logic lives in the Rust core; UI presentation lives in Flutter.

## Code Standards

- Run `flutter analyze` and `flutter test` before submitting changes.
- In the Rust codebase, run `cargo clippy` and `cargo test`.
- Write meaningful commit messages explaining the *why* behind your changes.

## Submitting Pull Requests

- Keep pull requests focused on a single topic or bug fix.
- Include automated tests for new functionality.
- Update documentation and architectural records where applicable.

