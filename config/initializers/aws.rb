Aws.config.update(
  region: IdentityConfig.store.aws_region,
  http_open_timeout: IdentityConfig.store.aws_http_timeout,
  http_read_timeout: IdentityConfig.store.aws_http_timeout
)
