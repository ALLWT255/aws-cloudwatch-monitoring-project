variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "vpc cidr block"
}
variable "public_subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "subnet cidr block"
}
variable "instance_type" {
  default     = "t3.micro"
  description = "EC2 instance type"
  type        = string
}