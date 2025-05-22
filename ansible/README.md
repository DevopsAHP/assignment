Install required tools:

Python
Ansible
AWS credentials configured

To install pip:
  apt install python3-pip -y

To install dependencies:
  pip install -r requirements.txt

To verify inventory is working:
  ansible-inventory -i inventory/aws_ec2.yaml --list




