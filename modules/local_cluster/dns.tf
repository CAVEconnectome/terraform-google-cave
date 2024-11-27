


resource "google_dns_record_set" "a_records" {
  for_each = var.dns_entries

  name         = "${each.value.domain_name}."dn
  type         = "A"
  ttl          = 300
  managed_zone = each.value.zone
  rrdatas      = [google_compute_address.cluster_ip.address]

  provider = google
}