variable "macie_scan_buckets" {
  type        = list(string)
  description = "Buckets that need to be scanned by Macie"
  default     = []
}