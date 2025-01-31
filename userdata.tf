# The userdata is built from the `userdata.tpl` file. It is limited to ~16k bytes,
# so comments about the userdata (~1k bytes) are here, not in the tpl file.
#
# userdata for EKS worker nodes to configure Kubernetes applications on EC2 instances
# In multipart MIME format so EKS can append to it. See:
#     https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data
#     https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
# If you  just provide a #!/bin/bash script like you can do when you provide the entire userdata you get
# an error at deploy time: Ec2LaunchTemplateInvalidConfiguration: User data was not in the MIME multipart format
#
# See also:
# https://aws.amazon.com/premiumsupport/knowledge-center/execute-user-data-ec2/
# https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
# https://aws.amazon.com/blogs/opensource/improvements-eks-worker-node-provisioning/
# https://github.com/awslabs/amazon-eks-ami/blob/master/files/bootstrap.sh
#

locals {
  kubelet_label_settings = [for k, v in var.kubernetes_labels : format("%v=%v", k, v)]
  kubelet_taint_settings = [for k, v in var.kubernetes_taints : format("%v=%v", k, v)]

  kubelet_label_args = (length(local.kubelet_label_settings) == 0 ? "" :
    "--node-labels=${join(",", local.kubelet_label_settings)}"
  )

  kubelet_taint_args = (length(local.kubelet_taint_settings) == 0 ? "" :
    "--register-with-taints=${join(",", local.kubelet_taint_settings)}"
  )

  kubelet_extra_args = join(" ", compact([local.kubelet_label_args, local.kubelet_taint_args, var.kubelet_additional_options]))

  userdata_vars = {
    before_cluster_joining_userdata = var.before_cluster_joining_userdata == null ? "" : var.before_cluster_joining_userdata
    kubelet_extra_args              = local.kubelet_extra_args
    bootstrap_extra_args            = var.bootstrap_additional_options == null ? "" : var.bootstrap_additional_options
    after_cluster_joining_userdata  = var.after_cluster_joining_userdata == null ? "" : var.after_cluster_joining_userdata
    shutdownGracePeriod             = var.kubelet_graceful_node_shutdown.shutdownGracePeriod
    shutdownGracePeriodCriticalPods = var.kubelet_graceful_node_shutdown.shutdownGracePeriodCriticalPods
  }

  cluster_data = {
    cluster_endpoint           = ""                 // local.get_cluster_data ? data.aws_eks_cluster.this[0].endpoint : ""
    certificate_authority_data = ""                 //local.get_cluster_data ? data.aws_eks_cluster.this[0].certificate_authority[0].data : ""
    cluster_name               = local.cluster_name // local.get_cluster_data ? data.aws_eks_cluster.this[0].name : local.cluster_name
  }

  need_bootstrap = local.enabled ? length(compact([local.kubelet_taint_args, var.kubelet_additional_options,
    local.userdata_vars.bootstrap_extra_args,
    local.userdata_vars.after_cluster_joining_userdata]
  )) > 0 : false

  # If var.userdata_override_base64 = "" then we explicitly set userdata to ""
  need_userdata = local.enabled && var.userdata_override_base64 == null

  userdata = local.need_userdata ? base64encode(templatefile("${path.module}/userdata.tpl", merge(local.userdata_vars, local.cluster_data))) : var.userdata_override_base64
}
