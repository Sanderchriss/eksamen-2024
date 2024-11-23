variable "region" {
  default = "eu-west-1"
}

variable "notification_email" {
  description = "E-postadressen som skal motta varsler"
  type        = string
  default     = "sado006@student.kristiania.no"
}