
resource "google_pubsub_topic" "l2cache" {
  name = "${var.cluster_prefix}_L2CACHE"
}

resource "google_pubsub_subscription" "l2cache_update" {
  name                 = "${var.cluster_prefix}_L2CACHE_WORKER"
  topic                = google_pubsub_topic.l2cache.name
  ack_deadline_seconds = 60
  retry_policy {
    maximum_backoff = "10s"
  }
}

resource "google_pubsub_topic" "pychunkedgraph_edits" {
  name = "${var.cluster_prefix}_PCG_EDIT"
}

resource "google_pubsub_subscription" "pychunkedgraph_remesh" {
  name                 = "${var.cluster_prefix}_PCG_HIGH_PRIORITY_REMESH"
  topic                = google_pubsub_topic.pychunkedgraph_edits.name
  ack_deadline_seconds = 600
  retry_policy {
    maximum_backoff = "10s"
  }
  filter = "attributes.remesh_priority=\"true\""
}

resource "google_pubsub_subscription" "pychunkedgraph_low_priority_remesh" {
  name                 = "${var.cluster_prefix}_PCG_LOW_PRIORITY_REMESH"
  topic                = google_pubsub_topic.pychunkedgraph_edits.name
  ack_deadline_seconds = 600
  retry_policy {
    maximum_backoff = "10s"
  }
  filter = "attributes.remesh_priority=\"false\""
}

resource "google_pubsub_subscription" "l2cache_trigger" {
  name                 = "${var.cluster_prefix}_${terraform.workspace}_L2CACHE_HIGH_PRIORITY_TRIGGER"
  topic                = google_pubsub_topic.pychunkedgraph_edits.name
  ack_deadline_seconds = 600
  retry_policy {
    maximum_backoff = "10s"
  }
  filter = "attributes.remesh_priority=\"true\""
}

resource "google_pubsub_subscription" "l2cache_trigger_low_priority" {
  name                 = "${var.cluster_prefix}_${terraform.workspace}_L2CACHE_LOW_PRIORITY_TRIGGER"
  topic                = google_pubsub_topic.pychunkedgraph_edits.name
  ack_deadline_seconds = 600
  retry_policy {
    maximum_backoff = "10s"
  }
  filter = "attributes.remesh_priority=\"false\""
}

# Skeletoncache topics and subscriptions
resource "google_pubsub_topic" "skeletoncache_high" {
  name = "${var.cluster_prefix}_SKELETON_CACHE_HIGH_PRIORITY"
}

resource "google_pubsub_topic" "skeletoncache_low" {
  name = "${var.cluster_prefix}_SKELETON_CACHE_LOW_PRIORITY"
}

resource "google_pubsub_topic" "skeletoncache_dead_letter" {
  name = "${var.cluster_prefix}_SKELETON_CACHE_DEAD_LETTER"
}

resource "google_pubsub_subscription" "skeletoncache_high_retrieve" {
  name                 = "${var.cluster_prefix}_SKELETON_CACHE_WORKER_HIGH_PRIORITY"
  topic                = google_pubsub_topic.skeletoncache_high.name
  ack_deadline_seconds = 600
  retry_policy {
    maximum_backoff = "10s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.skeletoncache_dead_letter.id
    max_delivery_attempts = 10
  }
}

resource "google_pubsub_subscription" "skeletoncache_low_retrieve" {
  name                 = "${var.cluster_prefix}_SKELETON_CACHE_WORKER_LOW_PRIORITY"
  topic                = google_pubsub_topic.skeletoncache_low.name
  ack_deadline_seconds = 600
  retry_policy {
    maximum_backoff = "10s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.skeletoncache_dead_letter.id
    max_delivery_attempts = 10
  }
}

resource "google_pubsub_subscription" "skeletoncache_dead_letter_retrieve" {
  name                 = "${var.cluster_prefix}_SKELETON_CACHE_WORKER_DEAD_LETTER"
  topic                = google_pubsub_topic.skeletoncache_dead_letter.name
  ack_deadline_seconds = 600
  retry_policy {
    maximum_backoff = "10s"
  }
}

# Allow Pub/Sub service agent to publish dead-lettered messages to the DL topic
resource "google_pubsub_topic_iam_member" "skeletoncache_dead_letter_publisher" {
  topic  = google_pubsub_topic.skeletoncache_dead_letter.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}