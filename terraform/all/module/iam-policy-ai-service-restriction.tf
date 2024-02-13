# restrict to west-2 and east-1; used by all roles
data "aws_iam_policy_document" "ai_service_restriction" {
  statement {
    sid    = "AIServiceRestriction"
    effect = "Deny"
    actions = [
      "bedrock:*",
      "codeguru-profiler:*",
      "codeguru-reviewer:*",
      "codewhisperer:*",
      "titan:*",
      "comprehend:*",
      "comprehendmedical:*",
      "devops-guru:*",
      "forecast:*",
      "healthlake:*",
      "kendra:*",
      "lex:*",
      "lookoutmetrics:*",
      "personalize:*",
      "polly:*",
      "q:*",
      "rekognition:*",
      "textract:*",
      "transcribe:*",
      "transcribemedical:*",
      "translate:*",
      "health-omics:*",
      "health-imaging:*",
      "healthscribe:*",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "ai_service_restriction" {
  name        = "AIServiceRestriction"
  path        = "/"
  description = "Deny all actions from AI-centered AWS services"
  policy      = data.aws_iam_policy_document.ai_service_restriction.json
}
