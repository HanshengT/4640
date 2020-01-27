#!/bin/bash -x

SYSTEMD_PATH="/etc/systemd/system"

TODOAPP_CONFIG_PATH="/home/todoapp/app/config"


scp -r "files" todoapp:~

ssh todoapp << EOF
    # Create user todoapp 
    create_user(){
        echo "Creating todoapp..."
        sudo useradd -p $(openssl passwd -1 P@ssw0rd) todoapp
        echo "Complete"
    }

    # Install package
    install_package(){
        echo "Installing packages..."
        sudo yum -y update
        sudo yum -y install git nodejs npm mongodb-server nginx 
        sudo systemctl enable mongod
        sudo systemctl start mongod
        echo "Complete"
    }

    # config firewall
    config_firewall(){
        echo "Configuring firewall..."
        sudo firewall-cmd --zone=public --add-service=http
        sudo firewall-cmd --zone=public --add-port=8080/tcp
        sudo firewall-cmd --runtime-to-permanent
        echo "Complete"
    }

    # Setup Todo App
    setup_todoapp(){
        echo "Set up todoapp"
        git clone https://github.com/timoguic/ACIT4640-todo-app.git app
        cd app
        sudo npm install 
        cd ~
        sudo mv -f app /home/todoapp
        sudo chown todoapp /home/todoapp/app
        cd ~
        sudo cp -f files/database.js "$TODOAPP_CONFIG_PATH"
        sudo cp -f files/nginx.conf "$TODOAPP_CONFIG_PATH"
        sudo cp -f files/todoapp.service "$SYSTEMD_PATH"
        
        sudo systemctl enable nginx
        sudo systemctl start nginx
        sudo systemctl daemon-reload
        sudo systemctl enable todoapp
        sudo systemctl start todoapp
        echo "Complete"
    }

create_user
install_package
config_firewall
setup_todoapp
exit
EOF