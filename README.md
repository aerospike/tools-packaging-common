# Server Packaging Common


This repository contains common scripts and files for packaging Aerospike Tools

## Getting Started

Shared packaging files are located in the [.github/packaging/common](.github/packaging/common) directory.
These scripts are used to build docker images for each supported OS distribution. 

Scripts in [.github/packaging/common](.github/packaging/common) should be implemented by each project. 
These include 
 - test/test_execute.bats
   - Test cases that install the package from JFrog and make sure the associated executables are available and execute. 
 - build_package.sh
   - This should call the Makefile or associated build script for the project, and calls the Makefile in pkg/ to build the package.
 - install_deps.sh
   - This script should have a function for each distribution that installs the dependencies for the project.
 - 

### Development Setup

You must have 
  - bash >= 4.3
  - docker
  - git

```bash
# Clone the repository
git clone https://github.com/aerospike/[REPOSITORY_NAME].git
cd [REPOSITORY_NAME]

# Add your setup steps here
```

## Project Structure

<!-- Describe your project structure here -->

```
.
├── .github/
│   ├── workflows/       # GitHub Actions workflows
│   └── dependabot.yml   # Dependabot configuration
└── etc
```


## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Security

For information on reporting security vulnerabilities, please see [SECURITY.md](SECURITY.md).

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

<!-- Add support information here -->

For questions or issues, please:
- Open an issue on GitHub
- Check existing documentation
- Contact the maintainers

---

**Remember to customize this README for your specific project!**
