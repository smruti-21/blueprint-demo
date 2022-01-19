data "aws_eks_cluster" "cluster" {
  name = element(concat(aws_eks_cluster.this.*.id, [""]), 0)
}

data "aws_eks_cluster_auth" "cluster" {
  name = element(concat(aws_eks_cluster.this.*.id, [""]), 0)
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
