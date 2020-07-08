#!/bin/sh
AWS_ACCESS_KEY_ID="AAAAAAAA"
AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXX"
AWS_S3BUCKET="mybucketname"
S3_MOUNT_PATH="/mnt/s3"
FUSE_URL="https://github.com/libfuse/libfuse/archive/fuse-3.9.2.tar.gz"
FUSE_PATH="/usr/src/fuse"
S3FS_URL="https://github.com/s3fs-fuse/s3fs-fuse/archive/v1.86.tar.gz"
S3FS_PATH="/usr/src/s3fs"

# Do not change anything below this

yum remove -y -q fuse fuse-s3fs &> /dev/null
yum install -y -q wget gcc libstdc++-devel gcc-c++ curl-devel libxml2-devel openssl-devel mailcap automake &> /dev/null

wget -q -O /tmp/fuse.tar.gz $FUSE_URL &> /dev/null
tar -xzf /tmp/fuse.tar.gz -C /tmp &> /dev/null
rm -f /tmp/fuse.tar.gz &> /dev/null
rm -rf /usr/src/fuse &> /dev/null
mv /tmp/libfuse-fuse* $FUSE_PATH &> /dev/null
cd $FUSE_PATH
,&> /dev/null
make &> /dev/null
make install &> /dev/null
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig &> /dev/null
ldconfig &> /dev/null
modprobe fuse &> /dev/null

wget -q -O /tmp/s3fs.tar.gz $S3FS_URL &> /dev/null
tar -xzf /tmp/s3fs.tar.gz -C /tmp &> /dev/null
rm -f /tmp/s3fs.tar.gz &> /dev/null
rm -rf /usr/src/s3fs &> /dev/null
mv /tmp/s3fs-fuse* $S3FS_PATH &> /dev/null
cd $S3FS_PATH
./autogen.sh &> /dev/null
./configure --prefix=/usr/local &> /dev/null
make &> /dev/null
make install &> /dev/null

yum install -y -q fuse-libs &> /dev/null

cat > ~/.passwd-s3fs <<EOF
$AWS_S3BUCKET:$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY
EOF

chmod 600 ~/.passwd-s3fs &> /dev/null
mkdir $S3_CACHE_PATH &> /dev/null
mkdir $S3_MOUNT_PATH &> /dev/null
chmod 777 $S3_CACHE_PATH $S3_MOUNT_PATH &> /dev/null
s3fs $AWS_S3BUCKET $S3_MOUNT_PATH &> /dev/null
