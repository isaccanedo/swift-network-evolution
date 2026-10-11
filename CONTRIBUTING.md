# Contributing to Swift Network Evolution

Welcome to the community! Contributions are welcomed and encouraged. Swift Network Evolution is part of the Swift ecosystem and closely aligns with the [contribution guidelines for the Swift project](https://swift.org/contributing).

## How You Can Help

* Reporting bugs with clear, reproducible steps via [GitHub Issues](https://github.com/apple/swift-network-evolution/issues)
* Improving documentation to make the project more accessible
* Adding or enhancing tests to improve reliability and coverage
* Adding ports to new platforms
* Triaging issues by providing feedback, testing, and validation
* Participating in the [Networking category on the Swift Forums](https://forums.swift.org/c/development/networking/129)

## Setting Up Your Environment

See the [README](./README.md#building-and-testing) for prerequisites and build (and test) instructions.

## Submitting Issues and Pull Requests

### Issues and Bugs

Use GitHub Issues to report bugs. When filing a bug, include your Swift version, OS, and the simplest possible steps to reproduce.

## Pull requests

Each pull request will be reviewed by a code owner before merging.

* Pull requests should contain small, incremental changes focused on one task; we may ask you to split up the work.
* Focus on one task. If a pull request contains several unrelated commits, we will ask for the pull request to be split up.
* Please squash work-in-progress commits. Each commit should stand on its own (including the addition of tests if possible). This allows us to bisect issues more effectively.
* After addressing review feedback, please rebase your commit so that we create a clean history in the `main` branch.
* Documentation is required. Please explain the "why" behind non-obvious decisions.

Please start with an Issue before opening Pull Requests that add a new functionality or expand the surface. The [Networking category on the Swift Forums](https://forums.swift.org/c/development/networking/129) is also a great place to discuss feature requests and larger overall project discussions.  

## Tests

All tests must pass on all supported platforms before a pull request can be merged. Unit tests are run automatically on pull request creation and updates. Pull requests that add new functionality should come with new automated tests.

See the [README](./README.md#building-and-testing) for quick references.
