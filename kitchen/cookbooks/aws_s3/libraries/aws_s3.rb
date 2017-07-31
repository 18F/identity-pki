require 'aws-sdk'

class AwsS3Error < Exception
end

# Simple class to copy content to/from s3.  Does it in memory, so this is meant
# for only small files and to be hooked into other resources.
class Chef::Recipe::AwsS3

  # Download an object from s3.  Return nil if the object doesn't exist, and
  # throws an exception if the bucket doesn't exist.
  #
  # @param bucket [String] the bucket to download from.
  # @param key [String] the path to download from.
  # @return [String] the contents of the object at that location.
  def self.download(bucket, key, print_warnings: true)
    s3 = Aws::S3::Resource.new(region: Chef::Recipe::AwsMetadata.get_aws_region)
    s3_bucket = s3.bucket(bucket)
    if not s3_bucket.exists?
      msg = "Bucket #{bucket} does not exist!"
      raise AwsS3Error.new(msg)
    end
    obj = s3_bucket.object(key)
    if !exists?(obj)
      msg = "Object in #{bucket} at path #{key} does  not exist.  Skipping download."
      Chef::Log.warn(msg) if print_warnings
      return nil
    end
    return obj.get.body.read
  end

  # Upload an object to s3.  Warns if the object exists, and raises an error if
  # the bucket does not.
  #
  # @param bucket [String] the bucket to upload to.
  # @param key [String] the path to upload to.
  # @param content [IO] content to upload.
  # @return [Aws::S3::Types::PutObjectOutput] the upload result from the sdk.
  def self.upload(bucket, key, content, print_warnings: true)
    s3 = Aws::S3::Resource.new(region: Chef::Recipe::AwsMetadata.get_aws_region)
    s3_bucket = s3.bucket(bucket)
    if not s3_bucket.exists?
      msg = "Bucket #{bucket} does not exist!"
      raise AwsS3Error.new(msg)
    end
    obj = s3_bucket.object(key)
    if exists?(obj)
      # Possibly should not overwrite here, but the bucket should have
      # versioning enabled.
      msg = "Object in bucket #{bucket} at path #{key} already exists!  Overwriting..."
      Chef::Log.warn(msg) if print_warnings
    end
    return obj.put(body: content)
  end

  # Check if an object exists, and handle unexpected errors.
  #
  # @param obj [Aws::S3::Object] object to check existence of.
  # @return [true,false] whether the object exists in s3.
  def self.exists?(obj)
    return obj.exists?
  rescue Aws::S3::Errors::Forbidden
    # https://github.com/aws/aws-sdk-ruby/issues/201
    return false
  end
end
