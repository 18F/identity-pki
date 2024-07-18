resource "aws_accessanalyzer_analyzer" "iam_access_analyzer" {
  analyzer_name = "IAMAccessAnalyzer"
}

resource "aws_accessanalyzer_analyzer" "unused_access" {
  analyzer_name = "IAMUnusedAccess"
  type          = "ACCOUNT_UNUSED_ACCESS"

  configuration {
    unused_access {
      unused_access_age = 90
    }
  }
}
