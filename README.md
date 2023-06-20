# setup-rabbitmq-action

This action handles the setup and teardown of a RabbitMQ container for running tests.

## Usage

```yaml
      - name: Setup infrastructure
        uses: Particular/setup-rabbitmq-action@v1.0.0
        with:
          connection-string-name: EnvVarToCreateWithConnectionString
          host-env-var-name: EnvVarToCreateWithHostName
          tag: PackageName
          imageTag: 3-management
```

`connection-string-name` and `tag` are required. `host-env-var-name`, and `imageTag` are optional

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
