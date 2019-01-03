
variable "region" {}
variable "env" {}
variable "id" {}
variable "vpc_id" {}
variable "elb_dns" {}
variable "component" {}

variable "notifications" {
  default = []
}

variable "recovery_notifications" {
  default = []
}

variable "composite_notifications" {
  default = []
}

variable "unhealthy_time_window" {
  default = "last_1h"
}
variable "unhealthy_critical_threshold" {
  default = "1"
}

variable "latency_time_window" {}
variable "latency_ok_threshold" {}
variable "latency_critical_threshold" {}

variable "rc5xx_time_window" {}
variable "rc5xx_ok_threshold" {}
variable "rc5xx_critical_threshold" {}


variable "requests_time_window" {}
variable "requests_ok_threshold" {}
variable "requests_critical_threshold" {}
