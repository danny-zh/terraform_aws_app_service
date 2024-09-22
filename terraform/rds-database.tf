#Create subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_main"
  subnet_ids = module.vpc.private_subnets

  tags = var.aws_resource_tags
}


#Create RDS instance
resource "aws_db_instance" "app_database_rds" {
  allocated_storage = var.db_storage
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_type
  #db_name   = "db${random_string.lb_id.result}${var.aws_resource_tags["project"]}${var.aws_resource_tags["environment"]}"
  db_name              = "db_mysql"
  username             = var.db_admin_username
  password             = var.db_admin_passwd
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot  = true
  publicly_accessible  = false # Or set to false for private access

  vpc_security_group_ids = [module.db_backend_security_group.security_group_id]

}
