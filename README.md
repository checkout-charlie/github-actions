# Checkout Charlie's Github Actions

## Quickstart

```yaml
# .github/workflows/deploy.yml

name: Deployment

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build image
        uses: checkout-charlie/github-actions/build-docker-image@main
        
#     - run: your tests here
        
      - name: Push to Humanitec
        uses: checkout-charlie/github-actions/humanitec-push-image@main
        with:
          humanitec_token: ${{ secrets.HUMANITEC_TOKEN }}
          humanitec_org: checkout-charlie

```

```yaml
# .github/workflows/create-pr-deployment.yml

name: Create PR deployment

on:
  pull_request_target:
    types: [ opened,  reopened]
    branches-ignore: ['dependabot/**']

jobs:
  create-pr-deployment:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy PR deployment
        uses: checkout-charlie/github-actions/humanitec-create-pr-environment@main
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
    branches-ignore: ['dependabot/**']

jobs:
  delete-pr-deployment:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Delete PR deployment
        uses: checkout-charlie/github-actions/humanitec-delete-pr-environment@main
        with:
          humanitec_token: ${{ secrets.HUMANITEC_TOKEN }}
          humanitec_org: checkout-charlie
          app_id: << app-id >> # app id on humanitec

```

## Actions

### build-docker-image

Builds an image leveraging on Github's local cache to store Docker's layer cache. As fast as it can get.

| Param         | Default          | Description                        |
|---------------|------------------|------------------------------------|
| build_args    | none             | Arguments passed to `docker build` |
| build_context | .                | Docker build context               |
| image_name    | $repository_name | Image name                         |
| image_tag     | $commit_hash     | Image tag                          |

### humanitec-push-image

Push an image to Humanitec's registry.

| Param               | Default          | Description                 |
|---------------------|------------------|-----------------------------|
| **humanitec_token** | **required**     | **Secret token**            |
| **humanitec_org**   | **required**     | **e.g. `checkout-charlie`** |
| image_name          | $repository_name | Image name                  |

### humanitec-create-pr-environment

Creates a deployment from a pull request. Image must be pushed to Humanitec's registry before.

| Param                  | Default              | Description                                |
|------------------------|----------------------|--------------------------------------------|
| **humanitec_token**    | **required**         | **Secret token**                           |
| **humanitec_org**      | **required**         | **e.g. `checkout-charlie`**                |
| **app_id**             | **required**         | **App id on HT**                           |    
| **source_environment** | **required**         | **Source environment where to clone from** |
| environment_name       | $pull_request_number | Generated environment name                 |    
| environment_type       | development          | Generated environment type                 |    
| image_name             | $repository_name     | name of the image                          |

### humanitec-delete-pr-environment

Delete a generated deployment after its pull request is cloded.

| Param                | Default              | Description                 |
|----------------------|----------------------|-----------------------------|
| **humanitec_token**  | **required**         | **Secret token**            |
| **humanitec_org**    | **required**         | **e.g. `checkout-charlie`** |
| **app_id**           | **required**         | App id on HT                |
| **environment_name** | $pull_request_number | Environment to delete       |

## Author

federico.infanti@checkout-charlie.com

## License

MIT


