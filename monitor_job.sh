#!/bin/bash

# Pass the Job ID as an argument
JOB_ID=$1
LOG_FILE="job_${JOB_ID}_resource_usage.csv"

# Initial message
echo "Monitoring job $JOB_ID for CPU, memory, and GPU usage (if applicable)..." > $LOG_FILE
echo "Timestamp, MaxRSS_MB, MaxVMSize_MB, AllocCPUs, GPU_Utilization_%, GPU_Mem_Used_MB, GPU_Mem_Total_MB" >> $LOG_FILE

# Function to check if the job is still running
function is_job_running {
    squeue -j $JOB_ID > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        return 1  # Job has finished
    else
        return 0  # Job is still running
    fi
}

# Function to check if the job has a GPU allocated
function has_gpu {
    srun --jobid=$JOB_ID nvidia-smi > /dev/null 2>&1
    if [ $? -ne 0 ];then
        return 1  # No GPU detected
    else
        return 0  # GPU detected
    fi
}

# Check if the job has GPU
GPU_EXISTS=false
if has_gpu; then
    GPU_EXISTS=true
    echo "GPU is available for this job." >> $LOG_FILE
else
    echo "No GPU detected for this job." >> $LOG_FILE
fi

# Start monitoring
while is_job_running; do
    # Get the current timestamp
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # Get CPU and memory usage
    SACCT_OUTPUT=$(sacct --job=$JOB_ID --format=MaxRSS,MaxVMSize,AllocCPUs --noheader | tail -n 1)
    MAX_RSS=$(echo $SACCT_OUTPUT | awk '{print $1}' | sed 's/K//g')  # Remove KB unit
    MAX_VMSIZE=$(echo $SACCT_OUTPUT | awk '{print $2}' | sed 's/K//g')  # Remove KB unit
    ALLOC_CPUS=$(echo $SACCT_OUTPUT | awk '{print $3}')

    # Convert units to MB (1KB = 1/1024 MB)
    MAX_RSS_MB=$(echo "scale=2; $MAX_RSS / 1024" | bc)
    MAX_VMSIZE_MB=$(echo "scale=2; $MAX_VMSIZE / 1024" | bc)

    # Get GPU usage (if GPU exists)
    if [ "$GPU_EXISTS" = true ]; then
        NVIDIA_OUTPUT=$(srun --jobid=$JOB_ID nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits)
        GPU_UTILIZATION=$(echo $NVIDIA_OUTPUT | awk -F ',' '{print $1}')
        GPU_MEM_USED=$(echo $NVIDIA_OUTPUT | awk -F ',' '{print $2}')
        GPU_MEM_TOTAL=$(echo $NVIDIA_OUTPUT | awk -F ',' '{print $3}')
    else
        GPU_UTILIZATION="N/A"
        GPU_MEM_USED="N/A"
        GPU_MEM_TOTAL="N/A"
    fi

    # Write the log entry
    echo "$TIMESTAMP, $MAX_RSS_MB, $MAX_VMSIZE_MB, $ALLOC_CPUS, $GPU_UTILIZATION, $GPU_MEM_USED, $GPU_MEM_TOTAL" >> $LOG_FILE

    # Wait for 60 seconds
    sleep 60
done

# Message when the job finishes
echo "Job $JOB_ID has finished. Stopping monitoring." >> $LOG_FILE
