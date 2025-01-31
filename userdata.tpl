#!/bin/bash
${before_cluster_joining_userdata}

%{ if length(kubelet_extra_args) > 0 }
export KUBELET_EXTRA_ARGS="${kubelet_extra_args}"
%{ endif }

KUBELET_CONFIG=/etc/kubernetes/kubelet/kubelet-config.json
echo "$(jq ".shutdownGracePeriod=\"${shutdownGracePeriod}\"" $KUBELET_CONFIG)" > $KUBELET_CONFIG
echo "$(jq ".shutdownGracePeriodCriticalPods=\"${shutdownGracePeriodCriticalPods}\"" $KUBELET_CONFIG)" > $KUBELET_CONFIG

/etc/eks/bootstrap.sh --apiserver-endpoint '${cluster_endpoint}' --b64-cluster-ca '${certificate_authority_data}' ${bootstrap_extra_args} '${cluster_name}'
${after_cluster_joining_userdata}
