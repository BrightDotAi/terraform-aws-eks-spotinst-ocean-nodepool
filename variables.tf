variable "region" {
  type        = string
  description = "AWS Region"
}

variable "eks_cluster_id" {
  type        = string
  description = "EKS Cluster identifier"
}

variable "ocean_controller_id" {
  type        = string
  description = "Ocean Cluster identifier, used by cluster controller to target this cluster. If unset, will use EKS cluster identifier"
  default     = null
}

variable "instance_profile" {
  type        = string
  description = "The AWS Instance Profile to use for Spotinst Worker instances. If not set, one will be created."
  default     = null
}

variable "metadata_http_tokens_required" {
  type        = bool
  default     = true
  description = "Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2."
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  default     = 2
  description = "The desired HTTP PUT response hop limit (between 1 and 64) for instance metadata requests."
}

variable "min_size" {
  type        = number
  description = "The lower limit of worker nodes the Ocean cluster can scale down to"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "The upper limit of worker nodes the Ocean cluster can scale up to"
  default     = null
}

variable "desired_capacity" {
  type        = number
  description = "The number of worker nodes to launch and maintain in the Ocean cluster"
  default     = 1
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Associate a public IP address to worker nodes"
  default     = false
}

variable "module_depends_on" {
  type        = any
  default     = null
  description = "Can be any value desired. Module will wait for this value to be computed before creating node group."
}

variable "disk_size" {
  type        = number
  description = <<-EOT
    Disk size in GiB for worker nodes. Defaults to 20. Ignored it `launch_template_id` is supplied.
    Terraform will only perform drift detection if a configuration value is provided.
    EOT
  default     = 20
}

variable "instance_types" {
  type        = list(string)
  default     = null
  description = <<-EOT
    List of instance type to use for this node group. Defaults to null, which allows all instance types.
    EOT
}

variable "ec2_ssh_key" {
  type        = string
  description = "SSH key pair name to use to access the worker nodes launced by Ocean"
  default     = null
}

variable "fallback_to_ondemand" {
  type        = bool
  description = "If no Spot instance markets are available, enable Ocean to launch On-Demand instances instead."
  default     = true
}

variable "subnet_ids" {
  description = "A list of subnet IDs to launch resources in"
  type        = list(string)
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security groups that will be attached to the autoscaling group"
}

variable "existing_workers_role_policy_arns" {
  type        = list(string)
  default     = []
  description = "List of existing policy ARNs that will be attached to the workers default role on creation"
}

variable "ami_image_id" {
  type        = string
  description = "AMI to use. Ignored of `launch_template_id` is supplied."
  default     = null
}

variable "ami_release_version" {
  type        = string
  description = "EKS AMI version to use, e.g. \"1.16.13-20200821\" (no \"v\"). Defaults to latest version for Kubernetes version."
  default     = null
  validation {
    condition = (
      length(compact([var.ami_release_version])) == 0 ? true :
      length(regexall("^\\d+\\.\\d+\\.\\d+-\\d+$", var.ami_release_version)) == 1
    )
    error_message = "Var ami_release_version, if supplied, must be like  \"1.16.13-20200821\" (no \"v\")."
  }
}

variable "ami_type" {
  type        = string
  description = <<-EOT
    Type of Amazon Machine Image (AMI) associated with the Ocean.
    Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64`, `AL2_x86_64_GPU`, and `AL2_ARM_64`.
    EOT
  default     = "AL2_x86_64"
  validation {
    condition = (
      contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64"], var.ami_type)
    )
    error_message = "Var ami_type must be one of \"AL2_x86_64\", \"AL2_x86_64_GPU\", and \"AL2_ARM_64\"."
  }
}


variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version. Required unless `ami_image_id` is provided."
  default     = null
  validation {
    condition = (
      length(compact([var.kubernetes_version])) == 0 ? true :
      length(regexall("^\\d+\\.\\d+$", var.kubernetes_version)) == 1
    )
    error_message = "Var kubernetes_version, if supplied, must be like \"1.16\" (no patch level)."
  }
}

variable "kubernetes_labels" {
  type        = map(string)
  description = <<-EOT
    Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument.
    Other Kubernetes labels applied to the EKS Node Group will not be managed.
    EOT
  default     = {}
}

variable "kubernetes_taints" {
  type        = map(string)
  description = "Key-value mapping of Kubernetes taints."
  default     = {}
}

variable "kubelet_additional_options" {
  type        = string
  description = <<-EOT
    Additional flags to pass to kubelet.
    DO NOT include `--node-labels` or `--node-taints`,
    use `kubernetes_labels` and `kubernetes_taints` to specify those."
    EOT
  default     = ""
  validation {
    condition = (length(compact([var.kubelet_additional_options])) == 0 ? true :
      length(regexall("--node-labels", var.kubelet_additional_options)) == 0 &&
      length(regexall("--node-taints", var.kubelet_additional_options)) == 0
    )
    error_message = "Var kubelet_additional_options must not contain \"--node-labels\" or \"--node-taints\".  Use `kubernetes_labels` and `kubernetes_taints` to specify labels and taints."
  }
}

variable "before_cluster_joining_userdata" {
  type        = string
  default     = ""
  description = "Additional `bash` commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
}

variable "after_cluster_joining_userdata" {
  type        = string
  default     = ""
  description = "Additional `bash` commands to execute on each worker node after joining the EKS cluster (after executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
}

variable "bootstrap_additional_options" {
  type        = string
  default     = ""
  description = "Additional options to bootstrap.sh. DO NOT include `--kubelet-additional-args`, use `kubelet_additional_args` var instead."
}

variable "userdata_override_base64" {
  type        = string
  default     = null
  description = <<-EOT
    Many features of this module rely on the `bootstrap.sh` provided with Amazon Linux, and this module
    may generate "user data" that expects to find that script. If you want to use an AMI that is not
    compatible with the Amazon Linux `bootstrap.sh` initialization, then use `userdata_override_base64` to provide
    your own (Base64 encoded) user data. Use "" to prevent any user data from being set.

    Setting `userdata_override_base64` disables `kubernetes_taints`, `kubelet_additional_options`,
    `before_cluster_joining_userdata`, `after_cluster_joining_userdata`, and `bootstrap_additional_options`.
    EOT
}

variable "update_policy_should_roll" {
  type        = bool
  default     = true
  description = "If true, roll the cluster when its configuration is updated"
}

variable "update_policy_batch_size_percentage" {
  type        = number
  default     = 25
  description = "When rolling the cluster due to an update, the percentage of the instances to deploy in each batch."
}

variable "autoscale_is_enabled" {
  type        = bool
  description = "Enable the Ocean Kubernetes Auto Scaler."
  default     = true
}

variable "autoscale_is_auto_config" {
  type        = bool
  description = "Automatically configure and optimize headroom resources."
  default     = true
}

variable "enable_automatic_and_manual_headroom" {
  type        = bool
  description = "Enables automatic and manual headroom to work in parallel. When set to false, automatic headroom overrides all other headroom definitions manually configured, whether they are at cluster or VNG level."
  default     = true
}

variable "kubelet_graceful_node_shutdown" {
  type = object({
    shutdownGracePeriod             = string
    shutdownGracePeriodCriticalPods = string
  })
  default = {
    shutdownGracePeriod             = "60s"
    shutdownGracePeriodCriticalPods = "20s"
  }
  description = "Configures graceful node shutdown.  Set to 0 to disable graceful node shutdowns https://kubernetes.io/docs/concepts/architecture/nodes/#graceful-node-shutdown"
}

variable "update_policy_launch_spec_ids" {
  type        = list(string)
  default     = null
  description = "List of virtual node group identifiers to be rolled during update."
}

variable "block_device_mappings" {
  type = map(object({
    delete_on_termination = optional(bool, true)
    encrypted             = optional(bool, true)
    volume_type           = string
    volume_size           = number
    throughput            = optional(number, null)
    iops                  = optional(number, null)

    dynamic_volume_size = optional(object({
      base_size              = number
      resource               = string
      size_per_resource_unit = number
    }), null)

    dynamic_iops = optional(object({
      base_size              = number
      resource               = string
      size_per_resource_unit = number
    }), null)
  }))
  default = {}
}

variable "autoscaler_max_vcpu" {
  type        = number
  description = "The maximum cpu in vCPU units that can be allocated to the cluster."
  default     = 1000
}

variable "autoscaler_max_memory_gib" {
  type        = number
  description = "The maximum memory in GiB units that can be allocated to the cluster."
  default     = 4000
}
