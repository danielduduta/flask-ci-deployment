locals {
  external_port = 443
  default_tags = {
    Provisioner = "terraform"
    Stack = var.k8s_service_name
  }
}

resource "aws_security_group" "sg" {
  name        = "${var.k8s_service_name} ALB SG"
  description = "${var.k8s_service_name} ALB SG"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = local.external_port
    to_port          = local.external_port
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.default_tags,
    {
    Name = "${var.k8s_service_name} ALB SG"
    })
}

resource "aws_lb" "lb" {
  name               = "${var.k8s_service_name}"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "dualstack"
  subnets            = var.vpc_public_subnets
  security_groups    = [aws_security_group.sg.id]
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
  enable_http2 = true
  enable_waf_fail_open = true
  idle_timeout = 60

  tags = merge(
    local.default_tags,
    {})
}

resource "aws_acm_certificate" "crt" {
  domain_name       = var.dns_service_name
  validation_method = "DNS"

  tags = merge(
    local.default_tags,
    {})

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "crt_dns" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.dns_zone_id
}

resource "aws_lb_listener" "lst" {
  load_balancer_arn = aws_lb.api.arn
  port              = local.external_port
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.crt.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.k8s_service_name}-${var.environment}"
  port        = var.k8s_service_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  deregistration_delay = 10

  health_check {
    healthy_threshold   = "2"
    interval            = "10"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/healthz"
    unhealthy_threshold = "2"
  }
  tags = local.default_tags
}

resource "kubernetes_manifest" "tgb" {
  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind = "TargetGroupBinding"
    metadata = {
      name= var.k8s_service_name
      namespace = var.namespace
    }
    spec = {
      serviceRef = {
        name = var.k8s_service_name
        port = var.k8s_service_port
      }
      targetGroupARN = aws_lb_target_group.tg.arn
      targetType = "ip"
    }
  }  

  depends_on = [aws_lb.lb, aws_lb_target_group.lb]
}

resource "aws_route53_record" "dns_a" {
  allow_overwrite = true
  zone_id         = var.dns_zone_id
  name            = var.dns_service_name
  type            = "A"

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "dns_aaaa" {
  allow_overwrite = true
  zone_id         = var.dns_zone_id
  name            = var.dns_service_name
  type            = "AAAA"

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = false
  }
}

