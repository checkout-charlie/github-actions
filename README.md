# Checkout Charlie's Github Actions

## Quickstart

Add the following to your project:

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
        with:
          production_stage: production # optional
        
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
          app_id: << app-id >> # app id on Humanitec

```

## Actions

### docker-build

Builds an image. It uses Github's local dependency cache to store Docker's layer cache for the fastest builds.

| Param            | Default          | Description                                                                      |
|------------------|------------------|----------------------------------------------------------------------------------|
| build_args       | none             | Arguments passed to `docker build`                                               |
| build_context    | .                | Docker build context                                                             |
| image_name       | $repository_name | Image name                                                                       |
| multi_stage      | false            | Whether to produce 2 images out of a multi-stage Dockerfile (production/testing) |
| production_stage | production       | Name of the production stage                                                     |
| testing_stage    | testing          | Name of the testing stage                                                        |
| testing_tag      | testing          | Image tag of the testing stage                                                   |
| image_tag        | $commit_hash     | Additional image tag beside the commit hash                                      |

** In case of multi-stage builds (production + dev dependencies), you can specify the production stage to be used as the final image. An additional image with all the stages will be built with the tag `testing`.
 
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

Delete a generated deployment after its pull request is closed.

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


