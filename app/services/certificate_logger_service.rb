require 'aws-sdk-s3'

class CertificateLoggerService
  class << self
    def log_certificate(certificate)
      return if bucket.blank?
      obj = bucket.object(certificate.logging_filename)
      obj.put(body: certificate.logging_content)
    end

    private

    def bucket
      @bucket ||= begin
        bucket_name = Figaro.env.client_cert_logger_s3_bucket_name
        Aws::S3::Resource.new.bucket(bucket_name) if bucket_name.present?
      end
    end
  end
end
