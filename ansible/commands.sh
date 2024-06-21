ansible all -i inventories/setup.yml -m ping

ansible all -i inventories/setup.yml -m setup -a "filter=ansible_distribution*"

ansible all -i inventories/setup.yml -m yum -a "name=httpd state=absent" --become
