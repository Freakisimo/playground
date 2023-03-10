provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "dagster_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "dagster-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              docker run \
                  --name dagster \
                  -p 3000:3000 \
                  -p 4000:4000 \
                  -e DAGSTER_HOME=/opt/dagster/dagster_home \
                  -v /opt/dagster:/opt/dagster \
                  dagster/dagster
              EOF

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key-pair.pem")
    host        = self.public_ip
  }

  tags = {
    Name = "dagster-instance"
  }
}

output "dagit_url" {
  value = "http://${aws_instance.dagster_instance.public_ip}:3000"
}

output "dagster_url" {
  value = "http://${aws_instance.dagster_instance.public_ip}:4000"
}