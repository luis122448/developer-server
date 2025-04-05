#!/bin/bash

ansible-playbook -i ./config/hadoop.ini ./ansible/hadoop_cluster_setup.yml --ask-become-pass --ask-pass