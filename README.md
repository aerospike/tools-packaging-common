# Server Packaging Common


This repository contains common scripts and files for packaging Aerospike Tools

## Getting Started

This repo contains shared packaging files. It should be added as a submodule of you project at [.github/packaging/common](.github/packaging/common) directory.
These scripts are used to build docker images for each supported OS distribution. 

Scripts in [.github/packaging/common](project-example) should be implemented by each project. 
These include
 - test/test_execute.bats
   - Test cases that install the package from JFrog and make sure the associated executables are available and execute. 
 - build_package.sh
   - This should call the Makefile or associated build script for the project, and calls the Makefile in pkg/ to build the package.
 - install_deps.sh
   - This script should have a function for each distribution that installs the dependencies for the project.


### Development Setup

You must have 
  - bash >= 4.3
  - docker
  - git

```bash
# Clone the repository

cd (your repository)
mkdir -p .github/packaging/project
git submodule add https://github.com/aerospike/server-packaging-common.git .github/packaging/common
cp -a .github/packaging/common/project-example/* .github/packaging/project/
# edit .github/packaging/project/* to match your project
mkdir pkg
cp .github/packaging/common/pkg-example/Makefile pkg/
# edit pkg/Makefile to match your project



```

## Project Structure

<!-- Describe your project-example structure here -->

```
This repository should be setup in your project as follows:
.
├── .github/
│   ├── packaging/common                    # Submodule of this directory
│   ├── packaging/project                   # copy of ./project-example
│   ├── workflows/build-artifacts.yaml      # copy of ./build-artifacts-example.yml configured for your project name
│   └── dependabot.yml                      # Dependabot configuration
└── pkg/Makefile                            # Makefile for building the package
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
