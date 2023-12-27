variable "gitlab"                 { default = "registry.gitlab.com/cyberpnkz/nginx" }
variable "github"                 { default = "ghcr.io/k44sh/nginx" }
variable "dockerhub"              { default = "docker.io/k44sh/nginx" }
variable "source"                 { default = "https://github.com/k44sh/nginx" }
variable "CI_PROJECT_TITLE"       { default = "$CI_PROJECT_TITLE" }
variable "CI_PROJECT_URL"         { default = "$CI_PROJECT_URL" }
variable "CI_JOB_STARTED_AT"      { default = "$CI_JOB_STARTED_AT" }
variable "CI_COMMIT_SHA"          { default = "$CI_COMMIT_SHA" }
variable "CI_PROJECT_DESCRIPTION" { default = "$CI_PROJECT_DESCRIPTION" }
variable "tag"                    { default = "$tag" }

group "default" { targets = [ "local" ] }

target "default" {
  cache-from = [
    "type=registry,ref=${dockerhub}:latest",
    "type=registry,ref=${dockerhub}:dev"
    ]
  labels    = {
    "org.opencontainers.image.url" = "${source}"
    "org.opencontainers.image.source" = "${source}"
    "org.opencontainers.image.documentation" = "${source}"
    "org.opencontainers.image.licenses" = "MIT"
    "org.opencontainers.image.vendor" = "k44sh"
  }
}

target "local" {
  inherits  = [ "default" ]
  output    = [ "type=docker" ]
  tags      = [ "nginx:local" ]
  labels    = { "org.opencontainers.image.version" = "local" }
}

target "registry" {
  inherits  = [ "default" ]
  output    = [ "type=image,push=true" ]
  labels    = {
    "org.opencontainers.image.title" = "${CI_PROJECT_TITLE}"
    "org.opencontainers.image.created" = "${CI_JOB_STARTED_AT}"
    "org.opencontainers.image.revision" = "${CI_COMMIT_SHA}"
    "org.opencontainers.image.description" = "${CI_PROJECT_DESCRIPTION}"
  }
}

### Pipeline Targets

target "quick" {
  inherits   = [ "registry" ]
  tags       = [ "${gitlab}:${CI_COMMIT_SHA}" ]
  platforms  = [ "linux/amd64" ]
}

target "schedule" {
  inherits   = [ "registry" ]
  tags       = [
    "${gitlab}:latest",
    "${github}:latest",
    "${dockerhub}:latest"
  ]
  platforms = [ 
    "linux/amd64",
    "linux/arm64",
    "linux/arm/v7"
  ]
}

target "dev" {
  inherits   = [ "registry" ]
  tags       = [
    "${gitlab}:dev",
    "${github}:dev",
    "${dockerhub}:dev"
    ]
  labels     = { "org.opencontainers.image.version" = "dev" }
  platforms = [ 
    "linux/amd64",
    "linux/arm64",
    "linux/arm/v7"
  ]
}

target "tag" {
  inherits  = [ "registry" ]
  tags      = [
    "${gitlab}:${tag}",
    "${gitlab}:latest",
    "${github}:${tag}",
    "${github}:latest",
    "${dockerhub}:${tag}",
    "${dockerhub}:latest"
  ]
  labels    = { "org.opencontainers.image.version" = "${tag}" }
  platforms = [ 
    "linux/amd64",
    "linux/arm64",
    "linux/arm/v7"
  ]
}