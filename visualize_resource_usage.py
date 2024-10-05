import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime

# Function to parse the timestamp in the CSV file
def parse_timestamp(timestamp_str):
    return datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')

# Load the CSV file
def load_resource_usage(csv_file):
    return pd.read_csv(csv_file, parse_dates=['Timestamp'], date_parser=parse_timestamp)

# Plot CPU and memory usage
def plot_cpu_memory_usage(df):
    fig, ax1 = plt.subplots(figsize=(10, 6))

    # Plot MaxRSS and MaxVMSize
    ax1.set_xlabel('Time')
    ax1.set_ylabel('Memory Usage (MB)')
    ax1.plot(df['Timestamp'], df['MaxRSS_MB'], label='MaxRSS_MB', color='tab:blue')
    ax1.plot(df['Timestamp'], df['MaxVMSize_MB'], label='MaxVMSize_MB', color='tab:green')
    ax1.tick_params(axis='y')
    ax1.legend(loc='upper left')

    # Plot AllocCPUs on a secondary axis
    ax2 = ax1.twinx()
    ax2.set_ylabel('Allocated CPUs')
    ax2.plot(df['Timestamp'], df['AllocCPUs'], label='AllocCPUs', color='tab:red')
    ax2.tick_params(axis='y')
    ax2.legend(loc='upper right')

    plt.title('CPU and Memory Usage Over Time')
    plt.show()

# Plot GPU usage if applicable
def plot_gpu_usage(df):
    if 'GPU_Utilization_%' in df.columns and df['GPU_Utilization_%'].notna().all():
        fig, ax = plt.subplots(figsize=(10, 6))

        # Plot GPU Utilization
        ax.set_xlabel('Time')
        ax.set_ylabel('GPU Utilization (%)')
        ax.plot(df['Timestamp'], df['GPU_Utilization_%'], label='GPU Utilization', color='tab:orange')

        # Plot GPU Memory Usage on a secondary axis
        ax2 = ax.twinx()
        ax2.set_ylabel('GPU Memory Usage (MB)')
        ax2.plot(df['Timestamp'], df['GPU_Mem_Used_MB'], label='GPU Memory Used', color='tab:purple')
        ax2.plot(df['Timestamp'], df['GPU_Mem_Total_MB'], label='GPU Memory Total', color='tab:brown')
        ax2.tick_params(axis='y')

        ax.legend(loc='upper left')
        ax2.legend(loc='upper right')

        plt.title('GPU Usage Over Time')
        plt.show()
    else:
        print("No GPU data available.")

# Main function to load the CSV and generate plots
def main(csv_file):
    df = load_resource_usage(csv_file)

    # Plot CPU and memory usage
    plot_cpu_memory_usage(df)

    # Plot GPU usage if available
    plot_gpu_usage(df)

# Replace 'job_12345_resource_usage.csv' with the path to your actual CSV file
if __name__ == "__main__":
    csv_file = 'job_12345_resource_usage.csv'
    main(csv_file)
