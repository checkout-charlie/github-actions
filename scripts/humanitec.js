const https = require('https');

const {HUMANITEC_TOKEN, HUMANITEC_ORG} = process.env;

const fetch = (method, path, body) => {
    return new Promise((resolve, reject) => {

        const request = https.request({
            host: 'api.humanitec.io',
            path: path,
            method: method,
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + HUMANITEC_TOKEN
            }
        }, (res) => {
            let output = Buffer.alloc(0);
            res.on('data', (chunk) => {
                output = Buffer.concat([output, chunk]);
            });
            res.on('end', () => {
                if (output.length > 0) {
                    resolve({
                        status: res.statusCode,
                        body: JSON.parse(output.toString())
                    });
                } else {
                    resolve({
                        status: res.statusCode
                    });
                }

            });
        });
        if (body) {
            request.write(JSON.stringify(body));
        }
        request.end();
    });
};


module.exports = {
    cloneEnvironment: async (appId, baseEnvId, envId, envType) => {
        const baseEnv = await fetch('GET', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${baseEnvId}`);
        if (baseEnv.status > 400) {
            throw `Unable to fetch environment /orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${baseEnvId}: ${baseEnv.status}`;
        }

        // pad number with leading zeros to get to 3 digits
        const paddedEnvId = envId.padStart(3, '0');

        const reqBody = {
            id: paddedEnvId,
            name: paddedEnvId,
            from_deploy_id: baseEnv.body.last_deploy.id,
            type: envType
        };
        console.log(`/orgs/${HUMANITEC_ORG}/apps/${appId}/envs`)
        console.log(reqBody);

        return fetch('POST', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs`, reqBody);
    },
    deleteEnvironment: async (appId, envId) => {
        // Clean up rules
        const paddedEnvId = envId.padStart(3, '0');
        const rules = await fetch('GET', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${paddedEnvId}/rules`);
        rules.body.forEach(rule => fetch('DELETE', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${paddedEnvId}/rules/${rule.id}`));

        // Delete Environment
        return fetch('DELETE', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${paddedEnvId}`);
    },
    addAutomationRule: async (appId, envId, match, type, updateTo) => {
        // pad number with leading zeros to get to 3 digits
        const paddedEnvId = envId.padStart(3, '0');
        return fetch('POST', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${paddedEnvId}/rules`, {
            active: true,
            match: match,
            type: type || "update",
            update_to: updateTo || "branch"
        });
    },
};
