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
    cloneEnvironment: async (appId, baseEnvId, envId, type) => {
        const baseEnv = await fetch('GET', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${baseEnvId}`);
        if (baseEnv.status > 400) {
            throw `Unable to fetch environment /orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${baseEnvId}: ${baseEnv.status}`;
        }

        const reqBody = {
            id: envId,
            name: envId,
            from_deploy_id: baseEnv.body.last_deploy.id,
            type: type || baseEnv.body.type
        };

        console.log(reqBody);

        return fetch('POST', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs`, reqBody);
    },
    deleteEnvironment: async (appId, envId) => {
        // Clean up rules
        const rules = await fetch('GET', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${envId}/rules`);
        rules.body.forEach(rule => fetch('DELETE', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${envId}/rules/${rule.id}`));

        // Delete Environment
        return fetch('DELETE', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${envId}`);
    },
    addAutomationRule: async (appId, envId, imagesFilter, match, type, updateTo) => {
        // Add an automation rule
        return fetch('POST', `/orgs/${HUMANITEC_ORG}/apps/${appId}/envs/${envId}/rules`, {
            active: true,
            imagesFilter: imagesFilter,
            match: match,
            type: type || "update",
            update_to: updateTo || "branch"
        });
    },

    listImages: async (imageId) => {

    },
    getSet: async (appId, setId) => {

    },
    createDelta: async (appId, delta) => {

    },
    deployDelta: async (appId, envId, deltaId) => {

    },
    createWebhook: async (appId, webhookId, url, headers, payload, triggers) => {

    },
    deleteWebhook: async (appId, webhookId) => {

    }
};
