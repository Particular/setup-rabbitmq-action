# setup-rabbitmq-action

This action handles the setup and teardown of a RabbitMQ container for running tests.

## Usage

```yaml
      - name: Setup infrastructure
        uses: Particular/setup-rabbitmq-action@v1.6.0
        with:
          connection-string-name: EnvVarToCreateWithConnectionString
          host-env-var-name: EnvVarToCreateWithHostName
          tag: PackageName
          imageTag: 3-management
          registry-login-server: index.docker.io
          registry-username: ${{ secrets.DOCKERHUB_USERNAME }}
          registry-password: ${{ secrets.DOCKERHUB_TOKEN }}}}
```

`connection-string-name` and `tag` are required. `host-env-var-name`, and `imageTag` are optional.

For logging into a container registry:

* `registry-login-server` defaults to `index.docker.io` and is not required if logging into Docker Hub.
* `registry-username` and `registry-password` are optional and will result in pulling the RabbitMQ container anonymously if omitted.

## Development

Open the folder in Visual Studio Code. If you don't already have them, you will be prompted to install remote development extensions. After installing them, and re-opening the folder in a container, do the following:

Log into Azure

```bash
az login
az account set --subscription SUBSCRIPTION_ID
```

Run the npm installation

```bash
npm install
```

When changing `index.js`, run `npm run prepare` afterwards to update the output in the `dist` folder.


## License

The scripts and documentation in this project are released under the [MIT License](LICENSE).
