resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 32
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  max_password_age               = 90
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
  hard_expiry                    = false  # Default noted in case we change later
}

# FedRAMP Requirements (https://github.com/18F/identity-security-private/issues/1932)
# Minimum password length is 32 characters
# Require at least one uppercase letter from Latin alphabet (A-Z)
# Require at least one lowercase letter from Latin alphabet (a-Z)
# Require at least one number
# Require at least one non-alphanumeric character ()
# Password expires in 90 day(s)
# Allow users to change their own password
# Remember last 24 password(s) and prevent reuse
