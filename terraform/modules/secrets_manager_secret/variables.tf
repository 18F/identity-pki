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

variable "secret_string" {
  type        = string
  description = "Secret"
  default     = "generateRandomPassword"
}

variable "replica_regions" {
  type        = list(any)
  description = "Regions for secret replication"
  default     = []
}

variable "replica_key_id" {
  type        = string
  description = "Secret"
  default     = ""
}
