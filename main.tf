
# create datadog monitors for this elb

locals {
  shortregion = "${replace(var.region, "-", "")}"
  full_id     = "${var.component}-${var.id}-${var.env}" 
  scope       = "elb"
  message     = <<EOF
```
    component:   ${var.component}
    id:          ${var.id}
    environment: ${var.env}
    scope:       ${local.scope}
    region:      ${local.shortregion}
    vpc:         ${var.vpc_id}
```
    {{#is_alert}}
    notifications: ${join(",", formatlist("@%s", var.notifications))}
    {{/is_alert}}
    {{#is_recovery}}
    notifications: ${length(var.recovery_notifications) > 0 ? join(",", formatlist("@%s", var.recovery_notifications)) : join(",", formatlist("@%s", var.notifications))}
    {{/is_recovery}}

    [aws console](https://console.aws.amazon.com/ec2/v2/home?region=${var.region}#LoadBalancers:search={{host.name}})
EOF
    composite_message =<<EOF
```
    component:    ${var.component}
```
    notifications: ${join(",", formatlist("@%s", var.composite_notifications))}
EOF
 
}


resource "datadog_monitor" "elb_unhealthy_host" {
  name               = "${local.full_id} elb-unhealthy-host"
  type               = "metric alert"
  escalation_message = "escalation: ${local.message}"
  message            = "${local.message}"

  query = "avg(${var.unhealthy_time_window}):max:aws.elb.un_healthy_host_count{hostname:${var.elb_dns}} > ${var.unhealthy_critical_threshold}"

  thresholds {
    ok       = "0"
    critical = "${var.unhealthy_critical_threshold}"
  }

  notify_no_data      = "false"
  renotify_interval   = "60"
  notify_audit        = "false"
  include_tags        = "true"
  require_full_window = "false"

  tags = [ 
    "component:${var.component}",
    "id:${var.id}",
    "environment:${var.env}",
    "scope:${local.scope}",
    "region:${local.shortregion}",
    "vpc:${var.vpc_id}"
  ]
}


resource "datadog_monitor" "elb_latency" {
  name               = "${local.full_id} elb-latency"
  type               = "metric alert"
  escalation_message = "escalation: ${local.message}"
  message            = "${local.message}"

  query = "avg(${var.latency_time_window}):avg:aws.applicationelb.target_response_time.average{hostname:${var.elb_dns}} > ${var.latency_critical_threshold}" 
  thresholds {
    ok       = "${var.latency_ok_threshold}"
    critical = "${var.latency_critical_threshold}"
  }

  notify_no_data      = "false"
  renotify_interval   = "60"
  notify_audit        = "false"
  include_tags        = "true"
  require_full_window = "false"

  tags = [ 
    "component:${var.component}",
    "id:${var.id}",
    "environment:${var.env}",
    "scope:${local.scope}",
    "region:${local.shortregion}",
    "vpc:${var.vpc_id}",
  ]
}


resource "datadog_monitor" "rc5xx_rate" {
  name               = "${local.full_id} elb-5xx-rate"
  type               = "query alert"
  message            = "${local.message}"
  escalation_message = "escalation: ${local.message}"

  query = "avg(${var.rc5xx_time_window}):max:aws.applicationelb.httpcode_target_5xx{hostname:${var.elb_dns}}.as_rate() > ${var.rc5xx_critical_threshold}"

  thresholds {
    ok       = "${var.rc5xx_ok_threshold}"
    critical = "${var.rc5xx_critical_threshold}"
  }

  notify_no_data      = "false"
  renotify_interval   = "60"
  notify_audit        = "false"
  include_tags        = "true"
  require_full_window = "false"

  tags = [ 
    "component:${var.component}",
    "id:${var.id}",
    "environment:${var.env}",
    "scope:${local.scope}",
    "region:${local.shortregion}",
    "vpc:${var.vpc_id}",
  ]
}


resource "datadog_monitor" "request_count" {
  name               = "${local.full_id} elb-request-count"
  type               = "query alert"
  message            = "${local.message}"
  escalation_message = "escalation: ${local.message}"

  query = "max(${var.requests_time_window}):max:aws.applicationelb.request_count{hostname:${var.elb_dns}} by {host}.as_rate() < ${var.requests_critical_threshold}"

  thresholds {
    ok       = "${var.requests_ok_threshold}"
    critical = "${var.requests_critical_threshold}"
  }

  notify_no_data      = "false"
  renotify_interval   = "60"
  notify_audit        = "false"
  include_tags        = "true"
  require_full_window = "false"

  tags = [ 
    "component:${var.component}",
    "id:${var.id}",
    "environment:${var.env}",
    "scope:${local.scope}",
    "region:${local.shortregion}",
    "vpc:${var.vpc_id}", 
  ]
}


resource "datadog_monitor" "composit_monitor" {
  name               = "${local.full_id} elb-composite"
  type               = "composite"
  escalation_message = "escalation: ${local.composite_message}"
  message            = "${local.composite_message}"

  query = <<EOF
  ${datadog_monitor.elb_unhealthy_host.id} || ${datadog_monitor.elb_latency.id} || ${datadog_monitor.rc5xx_rate.id} || ${datadog_monitor.request_count.id}
EOF

  notify_no_data      = "false"
  renotify_interval   = "60"
  notify_audit        = "false"
  include_tags        = "true"
  require_full_window = "false"

  tags = [ 
    "component:${var.component}",
    "id:${var.id}",
    "environment:${var.env}",
    "scope:${local.scope}",
    "region:${local.shortregion}",
    "vpc:${var.vpc_id}"
  ]
}

output "monitors" {
  value = [ 
    "${datadog_monitor.elb_unhealthy_host.id}",
    "${datadog_monitor.elb_latency.id}",
    "${datadog_monitor.rc5xx_rate.id}",
    "${datadog_monitor.request_count.id}"
  ]
}
