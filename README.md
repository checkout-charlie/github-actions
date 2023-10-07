# Checkout Charlie's Github Actions

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
      - name: Build test image
        uses: checkout-charlie/github-actions/build-image@main
        with:
          build_args: |
          -e MY_SECRET=${{ secrets.MY_SECRET }} \
          stage: testing

      - name: Run tests
        uses: checkout-charlie/github-actions/run-tests@main
        with:
          static: yarn lint && yarn test:static
          unit: yarn test:unit
          functional: yarn test:functional

      - name: Run E2E tests
        uses: checkout-charlie/github-actions/run-tests@main
        with:
          e2e: yarn test:e2e     # Will start a container
          e2e_port: 3000         # Required only if the image exposes multiple ports
          post: yarn test:coverage
          docker_args: | 
            -e MY_SECRET=${{ secrets.MY_SECRET }} \

      - name: Build dist image
        uses: checkout-charlie/github-actions/build-image@main
        with:
          build_args: |
          -e MY_SECRET=${{ secrets.MY_SECRET }} \
          stage: production

      - name: Push to Humanitec
        uses: checkout-charlie/github-actions/humanitec-push-image@main
        with:
          humanitec_token: ${{ secrets.HUMANITEC_TOKEN }}
          humanitec_org: checkout-charlie

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
        uses: checkout-charlie/github-actions/deploy-pr@main
        with:
          humanitec_token: ${{ secrets.HUMANITEC_TOKEN }}
          humanitec_org: checkout-charlie
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
        uses: checkout-charlie/github-actions/undeploy-pr@main
        with:
          humanitec_token: ${{ secrets.HUMANITEC_TOKEN }}
          humanitec_org: checkout-charlie
          app_id: << app-id >> # app id on Humanitec

```

### Tests

At the moment of writing Github doesn't allow composite actions to bubble up steps to the user action.
Use the `run-tests` action multiple times if you want to display individual tests as steps in your workflow:

```yaml
    - name: Static analysis
        uses: checkout-charlie/github-actions/run-tests@main
        with:
          static: yarn test:lint

    - name: Unit tests
        uses: checkout-charlie/github-actions/run-tests@main
        with:
          unit: yarn test:unit

    - name: E2E tests
        uses: checkout-charlie/github-actions/run-tests@main
        with:
          e2e: yarn test:e2e
          docker_args: |
            -e MY_SECRET=${{ secrets.MY_SECRET }} \
```

## Actions reference

Refer to `action-name/action.yaml` for the full list of parameters.

## Author

federico.infanti@checkout-charlie.com

## License

MIT


