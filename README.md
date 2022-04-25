# setup-rabbitmq-action

This action handles the setup and teardown of an Azure Service Bus namespace for running tests.

## Usage

```yaml
      - name: Setup infrastructure
        uses: Particular/setup-rabbitmq-action@v1.0.0
        with:
          connection-string-name: EnvVarToCreateWithConnectionString
          host-env-var-name: EnvVarToCreateWithHostName
          tag: PackageName
```

`connection-string-name` and `tag` are required. `host-env-var-name` is optional

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE).
