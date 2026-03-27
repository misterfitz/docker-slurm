# Slurm in Docker

### Docker/Podman images with Slurm Workload Manager installed

This repository contains setup files for Rocky Linux-based container images with the [Slurm Workload Manager](https://slurm.schedmd.com/) installed. These images are primarily designed to serve as an environment to experiment with Slurm or run unit/integration tests of code that will later be run on high-performance computing (HPC) resources.

Images are compatible with both **Docker** and **Podman**.

![Container Usage Demonstration](media/readme_container_demo.gif)


## Image Descriptions and Tags

This repository contains files which can be used to configure container images with Slurm installed. Two image versions are provided:
- A "base" version with Slurm installed and a minimal set of required packages
- A "full" version with everything in the base version, plus various system tools (Python, text editors, Git, GCC, etc.) meant to reflect the basic setup of typical HPC servers

Both image versions are configured such that the default user is either `root` (if the tag has "root" in the name) or a standard user with sudo privileges.

### Docker Hub repository: https://hub.docker.com/r/misterfitz/slurm

Images are tagged with Slurm version and EL version: `{variant}-{slurm_version}-{el_version}`

| Tag Pattern             | Base Image                                              | Build Context      | Default User |
|:------------------------|:--------------------------------------------------------|:-------------------|:-------------|
| base-{ver}-{el}         | [Rocky Linux](https://hub.docker.com/_/rockylinux)      | `dockerfile_base/` | standard     |
| base-root-{ver}-{el}    | [Rocky Linux](https://hub.docker.com/_/rockylinux)      | `dockerfile_base/` | root         |
| full-{ver}-{el}         | [Rocky Linux](https://hub.docker.com/_/rockylinux)      | `dockerfile_full/` | standard     |
| full-root-{ver}-{el}    | [Rocky Linux](https://hub.docker.com/_/rockylinux)      | `dockerfile_full/` | root         |

**Available versions:**

| Rocky Linux | Slurm Versions | Example Tag            |
|:------------|:---------------|:-----------------------|
| 9           | 24.11, 25.05   | `full-root-24.11-el9`  |

> **Note**: For the images with a standard user, the default username is `docker` and the default password is `rocky`.

### GitHub repository: https://github.com/misterfitz/docker-slurm

Dockerfiles and other configuration files for these images are stored in GitHub. The images are automatically built and published to [Docker Hub](https://hub.docker.com/) with a GitHub Actions workflow. The workflow runs once a month (to keep packages updated), in addition to any time a change is made to the `Dockerfile` for either image, the workflow file itself, or configuration files.

Slurm RPMs are sourced from the [omnivector-solutions/slurm-repo](https://github.com/omnivector-solutions/slurm-repo).


---

## Introduction to Docker

Docker is a platform designed for setting up and running containers. On a high level, containers bundle software, files, and system configuration options into a single, distributable environment.

From Docker's [official documentation](https://docs.docker.com/get-started/overview/):
> Docker provides the ability to package and run an application in a loosely isolated environment called a container. [...] Containers are lightweight and contain everything needed to run the application, so you do not need to rely on what is currently installed on the host. You can easily share containers while you work, and be sure that everyone you share with gets the same container that works in the same way.

Containers in many ways function similar to a virtual machine: you can install required dependencies, set configuration options, and define environment variables inside a container, and then share the container to any other system to reproduce a nearly identical environment. However, it is important to note that containers and virtual machines are NOT equivalent, and each has their own capabilities and limitations.

Some of the advantages of containers include:

- **Bundled dependencies**: Setting up a development environment or dependencies required to run an application often involves many manual steps. These steps can become time-consuming and tedious if performed manually on a per-system basis. However, if instead all dependencies are installed in a container, then the container can simply be transferred to different systems, and all dependencies and configuration will be transferred with it. This makes it extremely easy to set up and run your code on different systems.
- **Reproducibility**: Using containers allows you to run your code with identical dependency versions and system configuration, so the same code should behave identically on different machines.
- **Ability to install software without administrator privileges**: In many cases, you may not have administrator privileges on computing systems such as HPC clusters, but you may need certain dependencies that require administrator privileges to install. Many HPC clusters offer container software that provides a workaround: simply install your software in a container, and then you can transfer the container to the HPC cluster and run all required dependencies without administrator privileges.

For a list of useful Docker commands, refer to the [Docker Command-Line Reference](https://docs.docker.com/engine/reference/commandline/docker/).


## Usage Instructions

### Prerequisites

To use the images in this repository, ensure that you have first completed the following steps:
- Installed [Docker Desktop](https://docs.docker.com/desktop/) or [Podman](https://podman.io/docs/installation)
- Installed [Visual Studio Code](https://code.visualstudio.com/docs/setup/setup-overview) (VS Code)
  - Within VS Code, install the [Docker](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker) and [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extensions
- If you want to build images locally or customize the images, also [clone this repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) to your local system

> **Warning**: The standard user images by default use the username and password posted publicly in this repository. If security is of significant concern, it is recommended that you change the password by running `passwd` after starting the container.

### Try it Out!

To pull and run a container to quickly test it out and experiment with Slurm, first pull the image:

```Shell
# Docker
docker pull misterfitz/slurm:[TAG]
docker run --rm -it misterfitz/slurm:[TAG]

# Podman
podman pull docker.io/misterfitz/slurm:[TAG]
podman run --rm -it docker.io/misterfitz/slurm:[TAG]
```

Where `[TAG]` is selected from the table [above](#docker-hub-repository-httpshubdockercommisterfitzslurm) (e.g., `base-25.05-el9`).

### Docker Compose

A number of options must be configured to build the Docker images in this repository. This repository contains a [Docker Compose](https://docs.docker.com/compose/) configuration file `docker-compose.yml` that can streamline this process. It is compatible with both `docker compose` and `podman-compose`.

To use Docker Compose, open a terminal in the root of the repository. Then, run one of the following commands, depending on your use case:

| Use Case                                      | Image Source         | Command                            |
|:----------------------------------------------|:---------------------|:-----------------------------------|
| Basic testing in terminal                     | Pull from Docker Hub | `docker compose run --rm [TAG]`    |
| Create detached container                     | Pull from Docker Hub | `docker compose up -d [TAG]`       |
| Build image locally                           | Build locally        | `docker compose build build-[TAG]` |
| Remove containers created with Docker Compose | N/A                  | `docker compose down`              |

Where `[TAG]` is one of: `base`, `base-root`, `full`, `full-root`.

Many additional options can be configured in `docker-compose.yml`. Refer to the [Docker Compose reference](https://docs.docker.com/compose/) for further information.

### Visual Studio Code Development Containers

VS Code can be [run inside a container](https://code.visualstudio.com/docs/devcontainers/containers), thus using the container as a development environment with access to the full range of VS Code capabilities. This provides a useful application of the images inside this repository, allowing rapid testing of code that interfaces with Slurm.

#### devcontainer.json

The recommended way to use the images in this repository as a VS Code development container is by creating a `devcontainer.json` file. This file allows a [sizeable number of options](https://containers.dev/implementors/json_reference/) (hostname, which folders on the host system are mounted in the container, commands to run after creating the container, etc.) to be configured.

To use a `devcontainer.json` file for one of your projects, first navigate to the root directory of your project repository. Create a folder `.devcontainer/` and inside this folder, create a JSON file named `devcontainer.json`. You can add any desired [configuration options](https://containers.dev/implementors/json_reference/) to the `devcontainer.json` file you created. However, at minimum, the following options must be set:

| Key                  | Image Default User | Value                              |
|:---------------------|:-------------------|:-----------------------------------|
| `"image"`            | both               | `"misterfitz/slurm:[TAG]"`         |
| `"overrideCommand"`  | both               | `true`                             |
| `"postStartCommand"` | standard           | `"sudo /etc/startup.sh"`           |
| `"postStartCommand"` | root               | `"/etc/startup.sh"`                |

Where `[TAG]` is selected from the table [above](#docker-hub-repository-httpshubdockercommisterfitzslurm).

After setting up the `devcontainer.json` file, simply select the "Reopen in Container" option from the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension as illustrated below.

![Launching a VS Code Development Container](media/readme_launch_devcontainer.png)

A sample `devcontainer.json` file is shown below. This sample file illustrates how to set a desired container hostname, avoid Git "unsafe directory" errors, and install pip dependencies inside the container.

```JSON
{
    "image": "misterfitz/slurm:full-25.05-el9",
    "runArgs": ["--hostname=linux"],
    "overrideCommand": true,
    "postCreateCommand": "git config --global --add safe.directory ${containerWorkspaceFolder}",
    "postStartCommand": "sudo /etc/startup.sh",
    "postAttachCommand": "pip install -r ${containerWorkspaceFolder}/requirements.txt"
}
```

#### Attach to a Running Container

An alternative way to open VS Code in a Docker container without using a `devcontainer.json` file is to first create a *detached* container, either using Docker Compose as described [above](#docker-compose) or with `docker run -d`.

Then, as shown in the image below, open VS Code and navigate to the Docker extension menu. The detached container you created should appear. Right-click it and choose "Attach Visual Studio Code."

![Attaching VS Code to a Running Container](media/readme_attach_vscode.png)

### GitHub Actions

Another application of the images in this repository is running automated code testing that invokes Slurm commands, through a platform such as GitHub Actions. To run GitHub Actions workflows in one of the images in this repository, simply set the value of `jobs.<job_id>.container.image` to the desired Docker Hub repository and tag as illustrated below:

```YAML
jobs:
  build:
    name: Job Name
    runs-on: ubuntu-latest
    container:
      image: misterfitz/slurm:[TAG]
```

Where `[TAG]` is selected from the table [above](#docker-hub-repository-httpshubdockercommisterfitzslurm). Also make sure to run `sudo /etc/startup.sh` (for standard user images) or `/etc/startup.sh` (for root user images) if you override the default entrypoint for the container.

For more information, refer to the [GitHub Actions documentation](https://docs.github.com/en/actions/using-jobs/running-jobs-in-a-container).


## Project History, Capabilities, and Limitations

This project is a fork of [nathan-hess/docker-slurm](https://github.com/nathan-hess/docker-slurm), adapted to use Rocky Linux as the base OS with multiple Slurm versions and Podman compatibility.

Key changes from upstream:
- **Rocky Linux** base instead of Ubuntu
- **Multiple Slurm versions** via matrix CI builds (24.11, 25.05)
- **Podman compatible** — uses direct daemon calls instead of init system services
- **Slurm RPMs** from [omnivector-solutions/slurm-repo](https://github.com/omnivector-solutions/slurm-repo)

That said, as with any project, there are important limitations to be aware of:
- These images have a relatively basic Slurm setup. They do not use Slurm configuration features such as cgroups or a job accounting database.
- These images define a single-node setup. However, they could be relatively easily extended to a multi-node cluster through Docker Compose or Kubernetes.


## References

- [Slurm](https://slurm.schedmd.com/)
  - [Official Project Documentation](https://slurm.schedmd.com/)
  - [SUSE Slurm Setup Guide](https://documentation.suse.com/sle-hpc/15-SP3/html/hpc-guide/cha-slurm.html)
- [Docker](https://www.docker.com/)
  - [Getting Started Overview](https://docs.docker.com/get-started/overview/)
  - [Command-Line Reference](https://docs.docker.com/engine/reference/commandline/docker/)
  - [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Podman](https://podman.io/)
  - [Getting Started](https://podman.io/docs)
- [Docker Compose](https://docs.docker.com/compose/)
  - [Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Visual Studio Code](https://code.visualstudio.com/)
  - [Developing Inside a Container](https://code.visualstudio.com/docs/devcontainers/containers)
  - [Attach to a Container](https://code.visualstudio.com/docs/devcontainers/attach-container)
  - [Creating a Development Container](https://code.visualstudio.com/docs/devcontainers/create-dev-container)
  - [`devcontainer.json` File Reference](https://containers.dev/implementors/json_reference/)
- [GitHub Actions](https://docs.github.com/en/actions)
  - [Running jobs in a container](https://docs.github.com/en/actions/using-jobs/running-jobs-in-a-container)
