output "service_url" {
  value = google_cloud_run_service.app.status[0].url
}

output "sql_ip" {
  value = google_sql_database_instance.instance.private_ip_address
}

output "admin-db" {
  value     = "postgresql://${google_sql_user.database-admin-user.name}:${random_password.db_admin_pwd.result}@${google_sql_database_instance.instance.public_ip_address}:5432/${google_sql_database.database.name}"
  sensitive = true
}