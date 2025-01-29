rbac:
  create: true
controller:
  name: controller
  service:
    ## List of IP addresses at which the controller services are available
    ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
    ##
    ## todo make this a static ip from google externalIPs: []

    ## todo make this a static ip from google loadBalancerIP: ""
    loadBalancerIP: ${cluster_ip}
    externalTrafficPolicy: "Local"
