#get the data fro the global vars WS
data "terraform_remote_state" "global" {
  backend = "remote"
  config = {
    organization = var.org
    workspaces = {
      name = var.globalwsname
    }
  }
}

# Intersight Provider Information 
terraform {
  required_providers {
    intersight = {
      source = "CiscoDevNet/intersight"
      version = "1.0.26"
    }
  }
}



variable "org" {
  type        = string
}
variable "api_key" {
  type        = string
  description = "API Key"
}
variable "secretkey" {
  type        = string
  description = "Secret Key"
}
variable "globalwsname" {
  type        = string
  description = "TFC WS from where to get the params"
}
variable "mgmtcfgsshkeys" {
  type        = string
  description = "sshkeys"
}


provider "intersight" {
  apikey        =  base64decode(var.api_key)
  secretkey = base64decode(var.secretkey)
  endpoint      = "https://intersight.com"
}

data "intersight_organization_organization" "organization_moid" {
  name = local.organization
}

output "organization_moid" {
  value = data.intersight_organization_organization.organization_moid.results.0.moid
}


# IPPool moids
#data "intersight_ippool_pool" "ippool_moid" {
#  name  = local.ippool_list
#}

# Netcfg moids
#data "intersight_kubernetes_network_policy" "netcfg_moid" {
#  name  = local.netcfg_list
#}

# Sysconfig moids
#data "intersight_kubernetes_sys_config_policy" "syscfg_moid" {
#  name  = local.syscfg_list
#}


# kube cluster profiles
#resource "intersight_kubernetes_cluster_profile" "kubeprof" {
#  name = local.clustername 
#  wait_for_completion=false
#  organization {
#    object_type = "organization.Organization"
#    moid        = data.intersight_organization_organization.organization_moid.results.0.moid
#  }
#  cluster_ip_pools {
#	object_type = "ippool.Pool" 
#	moid = data.intersight_ippool_pool.ippool_moid.results.0.moid
#  }
#  management_config {
##	encrypted_etcd = false
#	load_balancer_count = local.mgmtcfglbcnt
#	ssh_keys = [ 
#		 base64decode(var.mgmtcfgsshkeys)
#	]
#	ssh_user = local.mgmtcfgsshuser
#	object_type = "kubernetes.ClusterManagementConfig" 
#  }
#  net_config {
#	moid = data.intersight_kubernetes_network_policy.netcfg_moid.results.0.moid
#	object_type = "kubernetes.NetworkPolicy" 
#  }
#
#  sys_config {
#	moid = data.intersight_kubernetes_sys_config_policy.syscfg_moid.results.0.moid
#	object_type = "kubernetes.SysConfigPolicy" 
#  }
#}



# IpPool moids
#data "intersight_ippool_pool" "ippoolmaster_moid" {
#  name  = local.ippoolmaster_list
#}
#
## IpPool moids
#data "intersight_ippool_pool" "ippoolworker_moid" {
#  name  = local.ippoolworker_list
#}
#
## Kube version moids
#data "intersight_kubernetes_version_policy" "kubever_moid" {
#  name  = local.kubever_list
#}
#
## Infra Config Policy
#data "intersight_kubernetes_virtual_machine_infra_config_policy" "infrapol" {
#  name  = local.infrapolname
#}
#
# Instance Type
#data "intersight_kubernetes_virtual_machine_instance_type" "instancetype" {
#  name  = local.instancetypename
#}

# Master
#resource "intersight_kubernetes_node_group_profile" "masternodegrp" {
#  name = local.mastergrpname
#  node_type = "ControlPlaneWorker"
#  desiredsize = local.masterdesiredsize
#   minsize = local.masterdesiredsize
#   maxsize = 2
#
#  ip_pools {
#        object_type = "ippool.Pool" 
#        moid = data.intersight_ippool_pool.ippoolmaster_moid.results.0.moid
#  }
#
#
#  cluster_profile {
#        object_type = "kubernetes.ClusterProfile" 
#        moid = intersight_kubernetes_cluster_profile.kubeprof.moid
#  }
#
#
#  kubernetes_version {
#        object_type = "kubernetes.VersionPolicy" 
#        moid = data.intersight_kubernetes_version_policy.kubever_moid.results.0.moid
#  }
#
#}

#Infra provider
#resource "intersight_kubernetes_virtual_machine_infrastructure_provider" "masterinfraprov" {
#	name = local.masterinfraname
#	infra_config_policy {
#		moid =  data.intersight_kubernetes_virtual_machine_infra_config_policy.infrapol.results.0.moid
#		object_type = "kubernetes.VirtualMachineInfraConfigPolicy"
#	}
#	instance_type {
#		moid =  data.intersight_kubernetes_virtual_machine_instance_type.instancetype.results.0.moid
#		object_type = "kubernetes.VirtualMachineInstanceType"
#	}
#	node_group {
#		moid = intersight_kubernetes_node_group_profile.masternodegrp.moid 
#		object_type = "kubernetes.NodeGroupProfile"
#	}

#}


#resource "intersight_kubernetes_cluster_profile" "kubeprofaction" {
#  depends_on = [
#        intersight_kubernetes_node_group_profile.masternodegrp
#  ]
#  action = "Deploy"
#  name = intersight_kubernetes_cluster_profile.kubeprof.name
#  organization {
#    object_type = "organization.Organization"
#    moid        = data.intersight_organization_organization.organization_moid.results.0.moid 
#  }
#
#}

data "intersight_kubernetes_cluster_profile" "kubeprofaction" {
  moid = module.iks_cluster.k8s_cluster_moid
}

data "intersight_kubernetes_cluster" "cluster" {
  moid = module.iks_cluster.k8s_cluster_moid
}
#Wait for cluster to come up and then outpt the kubeconfig, if successful
output "kube_config" {
#	value = data.intersight_kubernetes_cluster_profile.kubeprofaction.kube_config[0].kube_config
       value = data.intersight_kubernetes_cluster.cluster.results.0.kube_config
}


locals {
  organization= yamldecode(data.terraform_remote_state.global.outputs.organization)
  ippool_list = yamldecode(data.terraform_remote_state.global.outputs.ip_pool_policy)
  netcfg_list = yamldecode(data.terraform_remote_state.global.outputs.network_pod)
  syscfg_list = yamldecode(data.terraform_remote_state.global.outputs.network_service)
  clustername = yamldecode(data.terraform_remote_state.global.outputs.clustername)
  mgmtcfgetcd = yamldecode(data.terraform_remote_state.global.outputs.mgmtcfgetcd)
  mgmtcfglbcnt = yamldecode(data.terraform_remote_state.global.outputs.mgmtcfglbcnt)
  mgmtcfgsshuser = yamldecode(data.terraform_remote_state.global.outputs.mgmtcfgsshuser)
  ippoolmaster_list = yamldecode(data.terraform_remote_state.global.outputs.ip_pool_policy)
  ippoolworker_list = yamldecode(data.terraform_remote_state.global.outputs.ip_pool_policy)
  kubever_list = yamldecode(data.terraform_remote_state.global.outputs.k8s_version_name)
  infrapolname = yamldecode(data.terraform_remote_state.global.outputs.infrapolname)
  instancetypename = yamldecode(data.terraform_remote_state.global.outputs.instancetypename)
  mastergrpname = yamldecode(data.terraform_remote_state.global.outputs.mastergrpname)
  masterdesiredsize = yamldecode(data.terraform_remote_state.global.outputs.masterdesiredsize)
  masterinfraname = yamldecode(data.terraform_remote_state.global.outputs.masterinfraname)
}


module "iks_cluster" {
  source  = "terraform-cisco-modules/iks/intersight//"
  version = "2.1.2"

  # Kubernetes Cluster Profile  Adjust the values as needed.
  cluster = {
    name                = local.clustername 
    action              = "Deploy"
    wait_for_completion = true 
    worker_nodes        = 2
    load_balancers      = 5
    worker_max          = 20
    control_nodes       = 1
    ssh_user            = local.mgmtcfgsshuser
    ssh_public_key      = base64decode(var.mgmtcfgsshkeys)
  }

  # IP Pool Information (To create new change "use_existing" to 'false' uncomment variables and modify them to meet your needs.)
  ip_pool = {
    use_existing = true
    name         = local.ippoolmaster_list
    # ip_starting_address = "10.239.21.220"
    # ip_pool_size        = "20"
    # ip_netmask          = "255.255.255.0"
    # ip_gateway          = "10.239.21.1"
    # dns_servers         = ["10.101.128.15","10.101.128.16"]
  }

  # Sysconfig Policy (UI Reference NODE OS Configuration) (To create new change "use_existing" to 'false' uncomment variables and modify them to meet your needs.)
  sysconfig = {
    use_existing = true
    name         = local.syscfg_list 
    # domain_name  = "rich.ciscolabs.com"
    # timezone     = "America/New_York"
    # ntp_servers  = ["10.101.128.15"]
    # dns_servers  = ["10.101.128.15"]
  }

  # Kubernetes Network CIDR (To create new change "use_existing" to 'false' uncomment variables and modify them to meet your needs.)
  k8s_network = {
    use_existing = true
    name         = local.netcfg_list 
    ######### Below are the default settings.  Change if needed. #########
    # pod_cidr     = "100.65.0.0/16"
    # service_cidr = "100.64.0.0/24"
    # cni          = "Calico"
  }

  # Version policy (To create new change "use_existing" to 'false' uncomment variables and modify them to meet your needs.)
  versionPolicy = {
    useExisting    = true 
    policyName     = local.kubever_list
    iksVersionName = "1.21.10-iks.0"
  }

  # Trusted Registry Policy (To create new change "use_existing" to 'false' and set "create_new' to 'true' uncomment variables and modify them to meet your needs.)
  # Set both variables to 'false' if this policy is not needed.
  tr_policy = {
    use_existing = false
    create_new   = false
    # name         = "trusted-registry"
  }

  # Runtime Policy (To create new change "use_existing" to 'false' and set "create_new' to 'true' uncomment variables and modify them to meet your needs.)
  # Set both variables to 'false' if this policy is not needed.
  runtime_policy = {
    use_existing = false
    create_new   = false
    # name                 = "runtime"
    # http_proxy_hostname  = "t"
    # http_proxy_port      = 80
    # http_proxy_protocol  = "http"
    # http_proxy_username  = null
    # http_proxy_password  = null
    # https_proxy_hostname = "t"
    # https_proxy_port     = 8080
    # https_proxy_protocol = "https"
    # https_proxy_username = null
    # https_proxy_password = null
  }

  # Infrastructure Configuration Policy (To create new change "use_existing" to 'false' and uncomment variables and modify them to meet your needs.)
  infraConfigPolicy = {
    use_existing = true
    # platformType = "iwe"
    # targetName   = "falcon"
    #policyName = "clusterinfra"
    policyName = local.infrapolname
    # description  = "Test Policy"
    # interfaces   = ["iwe-guests"]
    # vcTargetName   = optional(string)
    # vcClusterName      = optional(string)
    # vcDatastoreName     = optional(string)
    # vcResourcePoolName = optional(string)
    # vcPassword      = optional(string)
  }

  # Addon Profile and Policies (To create new change "createNew" to 'true' and uncomment variables and modify them to meet your needs.)
  # This is an Optional item.  Comment or remove to not use.  Multiple addons can be configured.
  addons = [
    {
      createNew       = true 
      addonPolicyName = "smm"
      addonName       = "smm"
      # description     = "SMM Policy"
      # upgradeStrategy = "AlwaysReinstall"
      # installStrategy = "InstallOnly"
      # releaseVersion  = "1.7.4-cisco4-helm3"
      overrides = yamlencode({ "demoApplication" : { "enabled" : true } })
    },
    # {
    # createNew = true
    # addonName            = "ccp-monitor"
    # description       = "monitor Policy"
    # # upgradeStrategy  = "AlwaysReinstall"
    # # installStrategy  = "InstallOnly"
    # releaseVersion = "0.2.61-helm3"
    # # overrides = yamlencode({"demoApplication":{"enabled":true}})
    # }
  ]

  # Worker Node Instance Type (To create new change "use_existing" to 'false' and uncomment variables and modify them to meet your needs.)
  instance_type = {
    use_existing = false
    name         = "medium"
    cpu          = 8
    memory       = 32768
    disk_size    = 40
  }

  # Organization and Tag Information
  organization = "default"
#  tags         = var.tags
}

