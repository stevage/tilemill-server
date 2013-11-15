bash <<EOF
sudo apt-get -y install git
git clone https://github.com/stevage/tilemill-server
cd tilemill-server
nohup ./install.sh &
EOF
