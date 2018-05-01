#!/bin/bash

# Install CUDA 9.1 and Dependencies
sudo yum groupinstall -y "Development Tools" | tee
sudo yum groupinstall -y "Development Libraries" | tee

sudo yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r) | tee

function checkmd5() {
  md5_to_test=$1
  md5_from_file=$(md5sum "$2" | cut -d " " -f1)
  md5_results="Input: $md5_to_test\nFile:  $md5_from_file"
  if [[ $md5_to_test == $md5_from_file ]]
    then
      echo -e "\n\e[92mMD5 SUCCESS\e[39m\n$md5_results"
    else
      echo -e "\n\e[91mMD5 FAILURE\e[39m\n$md5_results"
      exit
  fi
}

CUDA_MD5=275932fb004e8344963c7ed96a28fd44
curl http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-9.1.85-1.x86_64.rpm -o cuda.rpm

checkmd5 $CUDA_MD5 cuda.rpm
sudo rpm -i cuda.rpm | tee
rm cuda.rpm
sudo yum install -y cuda | tee