variable "exclude_characters" {
  type        = string
  description = "String of the characters to exclude from the password."
  default     = ""
}

variable "exclude_lowercase" {
  type        = bool
  description = "Whether to exclude lowercase letters from the password."
  default     = false
}

variable "exclude_numbers" {
  type        = bool
  description = "Whether to exclude numbers from the password."
  default     = false
}

variable "exclude_punctuation" {
  type        = bool
  description = <<EOM
  Whether to exclude the following punctuation characters from the password: ! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ ` { | } ~ .
  EOM
  default     = false
}

variable "exclude_uppercase" {
  type        = bool
  description = "Whether to exclude uppercase letters from the password."
  default     = false
}

variable "include_space" {
  type        = bool
  description = "Whether to include the space character."
  default     = true
}

variable "password_length" {
  type        = number
  description = "Length of the password."
  default     = 32
}

variable "require_each_included_type" {
  type        = bool
  description = "Whether to include at least one upper and lowercase letter, one number, and one punctuation."
  default     = false
}

variable "secret_name" {
  type        = string
  description = "Name of the secret"
}

variable "recovery_window_in_days" {
  type        = number
  description = "number of days until the secret is no longer recoverable. Values include 0, 7-30 days"
  default     = 7
}

# For secrets that will have their values managed outside of terraform, a
# value of "" or a string that includes "generateRandomPassword" must be used.
#
# The literal string "generateRandomPassword" will be replaced with a randomly
# generated string based on the configured variables. Example:
#   secret_string       = "my_prefixed_password:generateRandomPassword"
#   password_length     = 4
#   exclude_numbers     = true
#   exclude_punctuation = true
# will create a secret in SecretsManager with a value like:
#   "my_prefixed_password:AbCd"
variable "secret_string" {
  type        = string
  description = "Secret"
  default     = "generateRandomPassword"
}

variable "secret_tags" {
  description = "The tags to apply to the secret"
  type        = map(string)
  default     = {}
}

variable "kms_key_id" {
  type        = string
  description = "KMS key used to encrypt the secret"
}

variable "replica_regions" {
  type = list(object({
    region             = string
    kms_replica_key_id = string
  }))
  description = "List of regions and associated replica keys to replicate to"
  default     = []
}
