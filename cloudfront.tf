# ------------------------------
# CloudFront Distribution (HTTPS in front of the EC2 app)
# ------------------------------
resource "aws_cloudfront_distribution" "app" {
  enabled = true

  origin {
    domain_name = aws_eip.app.public_dns
    origin_id   = "ec2-front"

    custom_origin_config {
      http_port              = 3000
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "ec2-front"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    # Managed policy: CachingDisabled
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    # Managed policy: AllViewer (forwards all headers/cookies/query strings)
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name    = "${var.project}-${var.environment}-cloudfront"
    Project = var.project
    Env     = var.environment
  }
}

# ------------------------------
# Output
# ------------------------------
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.app.domain_name
}
