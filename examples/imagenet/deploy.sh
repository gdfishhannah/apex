#!/bin/bash

# install package
pip install torch torchvision
pip uninstall Pillow
pip install Pillow-SIMD==5.2.0.post0


# create dataset
imagefile="/home/ImageNet"

if [ ! -x "$imagefile" ]; then
        mkdir /home/ImageNet
        mkdir /home/ImageNet/train
        mkdir /home/ImageNet/train/1
        
        cd /home/ImageNet/train/1
        wget http://farm4.static.flickr.com/3579/3338602889_c1c371939f.jpg -O 1.jpg
        
        i=2
        while [ $i -le 1000 ]
        do
                cp 1.jpg $i.jpg
                let i+=1
        done

        cd /home/ImageNet/train
        i=2
        while [ $i -le 10 ]
        do
                cp -r /home/ImageNet/train/1 /home/ImageNet/train/$i
                let i+=1
        done

        cp -r /home/ImageNet/train /home/ImageNet/val
fi

# install apex
apex_dir=/root/apex
cd $apex_dir
python uninstall apex -y
python setup.py install

cd $apex_dir/examples/imagenet/
chmod a+x *.sh
./DDP.sh
