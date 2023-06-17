module "vpc" {
  source = "git::https://github.com/Lavikavi/tf-module-vpc-1.git"

  for_each   = var.vpc
  cidr_block = each.value["cidr_block"]
  subnets    = each.value["subnets"]

  tags             = local.tags
  env              = var.env
  default_vpc_id   = var.default_vpc_id
  default_vpc_cidr = var.default_vpc_cidr
  default_vpc_rtid = var.default_vpc_rtid
}

module "docdb" {
  source = "git::https://github.com/Lavikavi/tf-module-docdb.git"

  for_each       = var.docdb
  subnets        = lookup(lookup(lookup(lookup(module.vpc, "main", null), "subnets", null), each.value["subnet_name"], null), "subnet_ids", null)
  allow_db_cidr  = lookup(lookup(lookup(lookup(module.vpc, "main", null), "subnets", null), each.value["allow_db_cidr"], null), "subnet_cidrs", null)
  engine_version = each.value["engine_version"]
  instance_count = each.value["instance_count"]
  instance_class = each.value["instance_class"]


  tags    = local.tags
  env     = var.env
  vpc_id  = local.vpc_id
  kms_arn = var.kms_arn
}

module "alb" {
  source = "git::https://github.com/Lavikavi/tf-module-alb.git"

  for_each       = var.alb
  subnets        = lookup(lookup(lookup(lookup(module.vpc, "main", null), "subnets", null), each.value["subnet_name"], null), "subnet_ids", null)
  allow_alb_cidr = each.value["name"] == "public" ? ["0.0.0.0/0"] : lookup(lookup(lookup(lookup(module.vpc, "main", null), "subnets", null), each.value["allow_alb_cidr"], null), "subnet_cidrs", null)
  name           = each.value["name"]
  internal       = each.value["internal"]


  tags   = local.tags
  env    = var.env
  vpc_id = local.vpc_id
}

module "app" {
  depends_on = [module.vpc, module.docdb, module.rds, module.elasticache, module.rabbitmq, module.alb]
  source     = "git::https://github.com/Lavikavi/tf-module-app1.git"

  for_each         = var.app
  instance_type    = each.value["instance_type"]
  name             = each.value["name"]
  desired_capacity = each.value["desired_capacity"]
  max_size         = each.value["max_size"]
  min_size         = each.value["min_size"]
  app_port         = each.value["app_port"]

  subnet_ids     = lookup(lookup(lookup(lookup(module.vpc, "main", null), "subnets", null), each.value["subnet_name"], null), "subnet_ids", null)
  vpc_id         = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  allow_app_cidr = lookup(lookup(lookup(lookup(module.vpc, "main", null), "subnets", null), each.value["allow_app_cidr"], null), "subnet_cidrs", null)

  env          = var.env
  bastion_cidr = var.bastion_cidr
  tags         = local.tags
}

