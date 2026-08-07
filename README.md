# setup-rabbitmq-action

This action handles the setup and teardown of a RabbitMQ container for running tests.

## Prerequisites

This action does not provision WSL or Docker itself. On Windows runners it requires [setup-wsl-action](https://github.com/Particular/setup-wsl-action) to run first in the same job. That action provisions WSL2 and Docker, keeps the instance alive, and exports the `WSL_DISTRIBUTION`, `WSL_IP`, and `WSL_TOOLS_MODULE_PATH` environment variables this action relies on. On Linux runners setup-wsl-action is a no-op but should still be included so the workflow is uniform.

If setup-wsl-action has not run, the action fails fast with a clear error.

## Usage

```yaml
steps:
- name: Setup WSL
  uses: Particular/setup-wsl-action@v1
- name: Setup RabbitMQ
  uses: Particular/setup-rabbitmq-action@v1.6.0
  with:
    connection-string-name: EnvVarToCreateWithConnectionString
    host-env-var-name: EnvVarToCreateWithHostName
    image-tag: 3-management
    registry-login-server: index.docker.io
    registry-username: ${{ secrets.DOCKERHUB_USERNAME }}
    registry-password: ${{ secrets.DOCKERHUB_TOKEN }}
```

`connection-string-name` is required. `host-env-var-name` and `image-tag` are optional.

For logging into a container registry when running on Windows:

* `registry-login-server` defaults to `index.docker.io` and is not required if logging into Docker Hub.
* `registry-username` and `registry-password` are optional and will result in pulling the RabbitMQ container anonymously if omitted.

On Linux runners the RabbitMQ container runs directly through Docker. On Windows runners it runs inside WSL2 provisioned by [setup-wsl-action](https://github.com/Particular/setup-wsl-action). Run that action first, see [Prerequisites](#prerequisites).

## Development

Open the folder in Visual Studio Code. If you don't already have them, you will be prompted to install remote development extensions. After installing them and reopening the folder in a container, do the following:

Run the npm installation

```bash
npm install
```

When changing `index.mjs`, either run `npm run dev` beforehand, which watches the file and recompiles it automatically, or run `npm run prepare` afterwards.

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE).
