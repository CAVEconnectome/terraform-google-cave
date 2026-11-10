
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

# A worker nacks a message when the failure is transient -- a downstream 429/503, or an l2
# cache that has not computed every level 2 id in the root yet. The default flat 10s backoff
# makes that useless for the l2 cache case: the retry lands long before pcgl2cache has
# computed the ids, and max_delivery_attempts is spent in ~100s. Dead-lettering is not a
# no-op here -- the dead-letter consumer adds the root id to the refusal list -- so a root
# that only needed a short wait would be permanently refused.
#
# Measured 2026-08-17: the real gaps were 111,83,170,127,154,174,311,342,440,407s. Pub/Sub
# escalates noisily and plateaued near 420s without reaching the 600s cap, so 10 attempts spanned
# 38.6 min, not the ~65 min ideal doubling implies. A frozen-database copy (CREATE DATABASE ...
# WITH TEMPLATE, which first pg_terminate_backend's every connection to the live database) took
# 34m38s and left the API returning 503 for 33 of them, so a healthy 8-level-2-id root exhausted
# its attempts during the outage's final minute and was permanently refused.
#
# maximum_backoff cannot help: 600s is the API maximum and the curve never reaches it. Raising
# minimum_backoff would stretch the window but delays the common case, where l2-cache retries
# resolve in one or two attempts -- so the attempt count, which has no ceiling, is the knob to
# turn. At the ~420s plateau 50 attempts is roughly 5 hours.
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
    minimum_backoff = var.skeletoncache_retry_min_backoff
    maximum_backoff = var.skeletoncache_retry_max_backoff
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.skeletoncache_dead_letter.id
    max_delivery_attempts = var.skeletoncache_max_delivery_attempts
  }
}

resource "google_pubsub_subscription" "skeletoncache_low_retrieve" {
  name                 = "${var.cluster_prefix}_SKELETON_CACHE_WORKER_LOW_PRIORITY"
  topic                = google_pubsub_topic.skeletoncache_low.name
  ack_deadline_seconds = 600
  retry_policy {
    minimum_backoff = var.skeletoncache_retry_min_backoff
    maximum_backoff = var.skeletoncache_retry_max_backoff
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.skeletoncache_dead_letter.id
    max_delivery_attempts = var.skeletoncache_max_delivery_attempts
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