import * as path from 'node:path';
import * as url from 'node:url';
import * as core from '@actions/core';
import * as exec from '@actions/exec';

const __dirname = path.dirname(url.fileURLToPath(import.meta.url));

const setupPs1 = path.resolve(__dirname, '../setup.ps1');
const cleanupPs1 = path.resolve(__dirname, '../cleanup.ps1');

const isPost = core.getState('IsPost');
core.saveState('IsPost', true);

const connectionStringName = core.getInput('connection-string-name', { required: true });
const hostEnvVarName = core.getInput('host-env-var-name');
const imageTag = core.getInput('image-tag');
const registryLoginServer = core.getInput('registry-login-server');
const registryUser = core.getInput('registry-username');
const registryPass = core.getInput('registry-password');

async function run() {
    try {
        if (!isPost) {
            console.log('Running setup action');

            const rabbitMQName = 'psw-rabbitmq-' + Math.round(10000000000 * Math.random());
            core.saveState('RabbitMQName', rabbitMQName);

            console.log('RabbitMQName = ' + rabbitMQName);

            await exec.exec('pwsh', [
                '-File', setupPs1,
                '-hostname', rabbitMQName,
                '-connectionStringName', connectionStringName,
                '-hostEnvVarName', hostEnvVarName,
                '-imageTag', imageTag,
                '-registryLoginServer', registryLoginServer,
                '-registryUser', registryUser,
                '-registryPass', registryPass
            ]);
        } else {
            console.log('Running cleanup');

            const rabbitMQName = core.getState('RabbitMQName');

            await exec.exec('pwsh', [
                '-File', cleanupPs1,
                '-RabbitMQName', rabbitMQName
            ]);
        }
    } catch (err) {
        core.setFailed(err);
        console.log(err);
    }
}

run();
