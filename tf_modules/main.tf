module "slackoapp" {
    source = "./modules/slacko-app"
    vpc_id = "vpc-0b54a9371b62c188e"
    subnet_cidr = "10.0.102.0/24"
    ssh_key = "YOUR_SSH_KEY"
    app_name = "YOUR_APP_NAME"
    app_instance = "t2.micro"
    db_instance = "t2.micro"
    app_tags ={
        env = "DEPLOY_ENV"
        project = "PROJECT_NAME"
        customer = "CUSTOMER_NAME"
    }
}

output "slackip" {
 value = module.slackoapp.slacko-app
}
