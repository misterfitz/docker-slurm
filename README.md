# Slurm Container Images for CI/CD

Pre-built Rocky Linux container images with [Slurm Workload Manager](https://slurm.schedmd.com/) — designed for automated testing in CI pipelines.

## Available Images

**Docker Hub:** [`misterfitz/slurm`](https://hub.docker.com/r/misterfitz/slurm)

Versioned tags follow the pattern `{variant}-{slurm_version}-{el_version}`:

| Tag                      | Contents                                    | Default User         |
|:-------------------------|:--------------------------------------------|:---------------------|
| `base-{ver}-{el}`        | Slurm + minimal dependencies                | standard (`docker`)  |
| `base-root-{ver}-{el}`   | Slurm + minimal dependencies                | root                 |
| `full-{ver}-{el}`        | Slurm + Python, Git, GCC, editors, etc.     | standard (`docker`)  |
| `full-root-{ver}-{el}`   | Slurm + Python, Git, GCC, editors, etc.     | root                 |

**Slurm versions:** 24.11, 25.05, 25.11, 26.05

**EL versions:** `el9` (Rocky Linux 9), `el10` (Rocky Linux 10 — requires an x86-64-v3 CPU, i.e. Intel Haswell / AMD Excavator or newer)

Example tags: `full-root-26.05-el9`, `base-24.11-el10`

### Convenience Tags

These always point to the newest Slurm version on Rocky Linux 9 (currently `26.05-el9`) and move whenever the images are rebuilt (monthly and on each release). Pin a versioned tag instead if you need reproducible builds.

| Tag         | Points to                |
|:------------|:-------------------------|
| `base`      | `base-26.05-el9`         |
| `base-root` | `base-root-26.05-el9`    |
| `full`      | `full-26.05-el9`         |
| `full-root` | `full-root-26.05-el9`    |
| `latest`    | `full-26.05-el9`         |

## Quick Start

```sh
docker run --rm -it misterfitz/slurm:full-root
```

## CI Usage

### GitHub Actions

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: misterfitz/slurm:full-root-26.05-el9
    steps:
      - uses: actions/checkout@v4
      - run: /etc/startup.sh
      - run: srun hostname
```

For standard user images, use `sudo /etc/startup.sh` instead.

### GitLab CI

```yaml
test:
  image: misterfitz/slurm:full-root-26.05-el9
  before_script:
    - /etc/startup.sh
  script:
    - srun hostname
```

### Other CI Systems

Any CI platform that supports container images will work. The key requirement is running `/etc/startup.sh` before invoking Slurm commands — this starts `munged`, `slurmctld`, and `slurmd`.

## Startup

The images include `/etc/startup.sh` which initializes all Slurm daemons. It must be called before running any Slurm commands:

- **Root images:** `/etc/startup.sh`
- **Standard user images:** `sudo /etc/startup.sh` (passwordless sudo is pre-configured)

The default `CMD` in the images already calls startup, so `docker run -it` works out of the box.

## Building Locally

```sh
docker compose build build-full-root   # or build-base, build-base-root, build-full
```

See `docker-compose.yml` for all build targets and configuration options.

## Project Details

Fork of [nathan-hess/docker-slurm](https://github.com/nathan-hess/docker-slurm), adapted for:
- **Rocky Linux** base (instead of Ubuntu)
- **Multiple Slurm versions** via matrix CI builds
- **Podman compatible** — direct daemon calls, no init system required
- Slurm RPMs built from [SchedMD source releases](https://download.schedmd.com/slurm/)

### Limitations

- Single-node Slurm setup (no multi-node cluster)
- No cgroups or job accounting database
- Standard user images use default credentials (`docker` / `rocky`)
