# Bun + hono + drizzle + gcp

This is a proof of concept for the following technologies:

- [Bun](https://bun.sh/) (as a typescript runtime)
- [hono](https://hono.dev/) (as a backend framework)
- [drizzle](https://orm.drizzle.team/) (as an ORM)
- [terraform](https://registry.terraform.io/providers/hashicorp/google) (IaC)
- [gcp](https://console.cloud.google.com/) (as the cloud provider)

Live version: [https://hono-app-mkulnruqtq-ey.a.run.app/](https://hono-app-mkulnruqtq-ey.a.run.app/)

## Development

To work locally, first [install bun](https://bun.sh/docs/installation) and then all the dependencies. For the database
you can use the docker-compose file.

```sh
bun install

# copy env variables and set them accordingly
cp .env.example .env
docker-compose -f docker-compose.local.yml up -d

bun run dev
```

## Infrastructure

The terraform file and therefore the deployment consists of the following three main services:

- Artifact Registry
    - Used to store the docker image for Cloud Run
    - Images can be pushed by hand (or ideally by CI/CD)
- Cloud Run
    - This is the runtime of this webserver
    - It runs docker images and is publicly exposed
    - HTTPS and Domain per default
- Cloud SQL
    - Postgres database
    - There is an `admin` user, it can be used to connect to it from the internet

## Deployment

Infrastructure changes will be applied by terraform, each Cloud Run Revision can be triggered by hand (or ideally by
CI/CD).

To get started, make sure the `gcloud` client as well as the docker login is installed.

### First deployment

There is a 60-second delay between the creation of the Artifact Registry and Cloud run, this is because Cloud Run
requires the Docker image to already be present. So use this time to push the first version.

### New revision

To deploy a new revision, execute `bun run deploy` or `bash deploy.sh`. This will first build an image, pushes it to the
Registry and then triggers a new revision on Cloud Run.

### Terraform state

The terraform state is currently stored local. To enable collaboration, this should be stored in a central storage
bucket.