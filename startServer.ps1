$SERVER="ec2-34-224-25-194.compute-1.amazonaws.com"
$USER="ubuntu"
$PEM="~/.ssh/valheim.pem"

scp -i $PEM env.list docker-compose.yml startup.sh $USER@${SERVER}:./
scp -i $PEM rclone.conf $USER@${SERVER}:/home/ubuntu/.config/rclone/rclone.conf
ssh -i $PEM $USER@${SERVER}

mkdir .config
chmod u+x startup.sh
./startup.sh
