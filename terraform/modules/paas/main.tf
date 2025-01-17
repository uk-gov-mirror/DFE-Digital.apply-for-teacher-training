terraform {
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "0.13.0"
    }
  }
}

provider "cloudfoundry" {
  api_url      = var.cf_api_url
  user         = var.cf_user
  password     = var.cf_user_password
  sso_passcode = var.cf_sso_passcode
}

resource "cloudfoundry_app" "web_app" {
  name                       = local.web_app_name
  docker_image               = var.app_docker_image
  health_check_type          = "process"
  health_check_http_endpoint = "/check"
  instances                  = var.web_app_instances
  memory                     = var.web_app_memory
  space                      = data.cloudfoundry_space.space.id
  strategy                   = "blue-green-v2"
  timeout                    = 180
  environment                = local.web_app_env_variables
  docker_credentials         = var.docker_credentials
  dynamic "routes" {
    for_each = local.web_app_routes
    content {
      route = routes.value.id
    }
  }
  dynamic "service_binding" {
    for_each = local.app_service_bindings
    content {
      service_instance = service_binding.value.id
    }
  }
}

resource "cloudfoundry_app" "clock" {
  name               = local.clock_app_name
  docker_image       = var.app_docker_image
  health_check_type  = "process"
  command            = "bundle exec clockwork config/clock.rb"
  instances          = var.clock_app_instances
  memory             = var.clock_app_memory
  space              = data.cloudfoundry_space.space.id
  strategy           = "blue-green-v2"
  timeout            = 180
  environment        = local.clock_app_env_variables
  docker_credentials = var.docker_credentials
  dynamic "service_binding" {
    for_each = local.app_service_bindings
    content {
      service_instance = service_binding.value.id
    }
  }
}

resource "cloudfoundry_app" "worker" {
  name               = local.worker_app_name
  docker_image       = var.app_docker_image
  health_check_type  = "process"
  command            = "bundle exec sidekiq -c 5 -C config/sidekiq.yml"
  instances          = var.worker_app_instances
  memory             = var.worker_app_memory
  space              = data.cloudfoundry_space.space.id
  strategy           = "blue-green-v2"
  timeout            = 180
  environment        = local.worker_app_env_variables
  docker_credentials = var.docker_credentials
  dynamic "service_binding" {
    for_each = local.app_service_bindings
    content {
      service_instance = service_binding.value.id
    }
  }
}

resource "cloudfoundry_route" "web_app_cloudapps_digital_route" {
  domain   = data.cloudfoundry_domain.london_cloudapps_digital.id
  space    = data.cloudfoundry_space.space.id
  hostname = local.web_app_name
}

resource "cloudfoundry_route" "web_app_service_gov_uk_route" {
  domain   = data.cloudfoundry_domain.apply_service_gov_uk.id
  space    = data.cloudfoundry_space.space.id
  hostname = local.service_gov_uk_host_names[var.app_environment]
}

resource "cloudfoundry_route" "web_app_education_gov_uk_route" {
  domain   = data.cloudfoundry_domain.apply_education_gov_uk.id
  space    = data.cloudfoundry_space.space.id
  hostname = local.service_gov_uk_host_names[var.app_environment]
}

resource "cloudfoundry_service_instance" "postgres" {
  name         = local.postgres_service_name
  space        = data.cloudfoundry_space.space.id
  service_plan = data.cloudfoundry_service.postgres.service_plans[var.postgres_service_plan]
  json_params  = jsonencode(local.postgres_params)
}

resource "cloudfoundry_service_instance" "redis" {
  name         = local.redis_service_name
  space        = data.cloudfoundry_space.space.id
  service_plan = data.cloudfoundry_service.redis.service_plans[var.redis_service_plan]
}

resource "cloudfoundry_service_key" "postgres-readonly-key" {
  name             = "${local.postgres_service_name}-readonly-key"
  service_instance = cloudfoundry_service_instance.postgres.id
}

resource "cloudfoundry_service_key" "redis-key" {
  name             = "${local.redis_service_name}-key"
  service_instance = cloudfoundry_service_instance.redis.id
}
