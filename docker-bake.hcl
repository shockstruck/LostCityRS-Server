target "docker-metadata-action" {}

variable "APP" {
  default = "lostcityrs-server"
}

variable "SOURCE" {
  default = "https://github.com/LostCityRS"
}

// renovate: datasource=docker depName=oven/bun
variable "BUN_VERSION" {
  default = "1.3.10"
}

// renovate: datasource=docker depName=eclipse-temurin versioning=docker
variable "JRE_VERSION" {
  default = "21.0.10_7-jre"
}

variable "UPSTREAM_VERSION" {
  default = "${BUN_VERSION}"
}

variable "VERSION" {
  default = "${UPSTREAM_VERSION}"
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
  args = {
    VERSION     = "${VERSION}"
    BUN_VERSION = "${BUN_VERSION}"
    JRE_VERSION = "${JRE_VERSION}"
  }
  labels = {
    "org.opencontainers.image.source"        = "https://github.com/shockstruck/LostCityRS-Server"
    "org.opencontainers.image.title"         = "${APP}"
    "org.opencontainers.image.description"   = "LostCityRS RuneScape Server ${VERSION}"
    "org.opencontainers.image.version"       = "${VERSION}"
    "org.opencontainers.image.vendor"        = "shockstruck"
    "org.opencontainers.image.url"           = "https://github.com/shockstruck/LostCityRS-Server"
    "org.opencontainers.image.documentation" = "${SOURCE}"
    "upstream.version"                       = "${UPSTREAM_VERSION}"
    "upstream.source"                        = "${SOURCE}"
  }
}

target "image-local" {
  inherits = ["image"]
  output   = ["type=docker"]
  tags     = ["${APP}:${VERSION}", "${APP}:latest"]
}

target "image-all" {
  inherits = ["image"]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
