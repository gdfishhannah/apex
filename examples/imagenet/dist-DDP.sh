#!/usr/bin/env bash

nnode=2  #nodes
node_rank=$1    #命令行参数 ./dist-DDP.sh 0
ip=192.168.2.12   #127.0.0.1
port=23331

batchsize_pool=('128' '32') # '64' '32' '16' '8')
gpu_num_pool=('8') # '4' '2' '1')

exec_file=main.py
epochs=10
workers=6 #一个gpu对应几个进程异步读取数据
model=resnet50
# use_fp16="--fp16"
# use_prof="--prof"
data=/home/ImageNet

for ((i=0; i<${#gpu_num_pool[@]}; i++)) # 以gpu数为最外层循环，gpu多跑得快
do
    gpu_num=${gpu_num_pool[i]}
    for ((j=0; j<${#batchsize_pool[@]}; j++))
    do
        ulimit -n 102400
        ulimit -n

        batch_size=${batchsize_pool[j]}

        echo DDP:
        echo batch size: $batch_size
        echo GPU number: $gpu_num
        echo epoch number: $epochs
        echo worker number per gpu: $workers
        echo running...

        if [ $gpu_num = 1 ];then
            export CUDA_VISIBLE_DEVICES=0
        elif [ $gpu_num = 2 ];then
            export CUDA_VISIBLE_DEVICES=0,1
        elif [ $gpu_num = 4 ];then
            export CUDA_VISIBLE_DEVICES=0,1,2,3
        else
            export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
        fi

        dist_parameter="--nnode=$nnode --node_rank=$node_rank --nproc_per_node=$gpu_num --master_addr=$ip --master_port=$port"
        parameter="$use_fp16 $use_prof --arch $model --epoch $epochs --workers $workers --batch-size=$batch_size $data"
        if [[ $use_fp16 = "--fp16" ]];then
            log_file="batchsize$batch_size-gpu$gpu_num-epoch$epochs-worker$workers-fp16-node$1.log"
        else
            log_file="batchsize$batch_size-gpu$gpu_num-epoch$epochs-worker$workers-fp32-node$1.log"
        fi

        date > $log_file
        python --version 2>> $log_file
        echo "python -m torch.distributed.launch --nproc_per_node=$gpu_num $exec_file $parameter" >>  $log_file
        python -m torch.distributed.launch $dist_parameter $exec_file $parameter >> $log_file
        date >> $log_file

        echo -e done"\n"
    done
done
