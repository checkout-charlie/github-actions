# Checkout Charlie's Github Actions
## Available actions
### Kubernetes container images

- **build**
- **run-tests**

### Humanitec deployments

- **humanitec-push-image**
- **humanitec-deploy-pr**
- **humanitec-undeploy-pr**
- **humanitec-set-image-automation**

### Parameters

Refer to `action-name/action.yaml` for the full list of parameters.

## Recipes

### Build, test and push

```yaml
# .github/workflows/deploy.yml

name: Deployment

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build images
        uses: checkout-charlie/github-actions/build@v2
        with:
          build_args: |
            -e MY_SECRET=${{ secrets.MY_SECRET }} \
          stages: test, dist #these reflect the stages in the dockerfile

      - name: Run tests
        uses: checkout-charlie/github-actions/run-tests@v2
        with:
          static: yarn lint && yarn test:static
          unit: yarn test:unit
          functional: yarn test:functional
          post: yarn test:coverage
          image_stage: test # default

      - name: Run E2E tests
        uses: checkout-charlie/github-actions/run-tests@v2
        with:
          e2e: yarn test:e2e     # Will start a container
          e2e_port: 3000         # Required only if the image exposes multiple ports or is using cypress
          docker_args: | 
            -e MY_SECRET=${{ secrets.MY_SECRET }} \
          env_file: .env.dist    # mandatory
          cypress_node_version: 14.x # Only if Cypress is used to run the E2E test

      - name: Push to Humanitec
        uses: checkout-charlie/github-actions/humanitec-push-image@v2
        with:
          humanitec_token: ${{ secrets.HUMANITEC_TOKEN }}

```

### Deploy PRs to Humanitec

```yaml
# .github/workflows/create-pr-deployment.yml

name: Create PR deployment

on:
  pull_request_target:
    types: [ opened,  reopened]

jobs:
  create-pr-deployment:
    runs-on: ubuntu-latest
    if: ${{ github.actor != 'dependabot[bot]' && github.actor != 'renovate[bot]' }}
    steps:
      - uses: actions/checkout@v3
      - name: Deploy PR deployment
        uses: checkout-charlie/github-actions/deploy-pr@v2
        with:
          humanitec_token: ${{ secrets.HUMANITEC_TOKEN }}
          source_environment: << base-environment >> # source environment where to clone from
          app_id: << app-id >> # app id on humanitec

```

```yaml
# .github/workflows/delete-pr-deployment.yml

name: Delete PR deployment

on:
  pull_request_target:
    types: [ closed ]

jobs:
  delete-pr-deployment:
    runs-on: ubuntu-latest
    if: ${{ github.actor != 'dependabot[bot]' && github.actor != 'renovate[bot]' }}
    steps:
      - uses: actions/checkout@v3
      - name: Delete PR deployment
        uses: checkout-charlie/github-actions/undeploy-pr@v2
        with:
          humanitec_token: ${{ secrets.HUMANITEC_TOKEN }}
          app_id: << app-id >> # app id on Humanitec

```

### Tests

At the moment of writing Github doesn't allow composite actions to bubble up steps to the user action.
Use the `run-tests` action multiple times if you want to display individual tests as steps in your workflow:

```yaml
    - name: Run static analysis
        uses: checkout-charlie/github-actions/run-tests@v2
        with:
          static: yarn test:lint

    - name: Run unit tests
        uses: checkout-charlie/github-actions/run-tests@v2
        with:
          unit: yarn test:unit

    - name: Run E2E tests
        uses: checkout-charlie/github-actions/run-tests@v2
        with:
          e2e: yarn test:e2e
          docker_args: |
            -e MY_SECRET=${{ secrets.MY_SECRET }} \
```

## License

MIT


