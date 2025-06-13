variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_user" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "alarm_actions" {
  description = "List of ARNs to notify for alarms"
  type        = list(string)
  default     = []
}

variable "instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}







# variable "subnet_ids" {
#   description = "List of subnet IDs for the RDS subnet group"
#   type        = list(string)
# }

# variable "db_user" {
#   description = "Username for the RDS instance"
#   type        = string
# }

# variable "db_password" {
#   description = "Password for the RDS instance"
#   type        = string
#   sensitive   = true
# }

# variable "db_name" {
#   description = "Database name for the RDS instance"
#   type        = string
# }

# variable "security_groups" {
#   description = "List of security group IDs to associate with the RDS instance"
#   type        = list(string)
# }

# variable "environment" {
#   description = "Environment for the RDS instance (e.g., dev, prod)"
#   type        = string
# }

# variable "alarm_actions" {
  
# }

