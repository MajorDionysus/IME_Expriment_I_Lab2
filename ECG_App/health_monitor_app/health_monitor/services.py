import numpy as np
import pywt
from scipy.signal import butter, filtfilt, resample
import heartpy as hp
from scipy.io import loadmat

def butter_bandpass(lowcut, highcut, fs, order):
    nyq = 0.5 * fs
    low = lowcut / nyq
    high = highcut / nyq
    b, a = butter(order, [low, high], btype='band')
    return b, a

def butter_bandpass_filter(data, lowcut, highcut, fs, order=5):
    b, a = butter_bandpass(lowcut, highcut, fs, order=order)
    y = filtfilt(b, a, data)
    return y

def butter_stopband(lowcut, highcut, fs, order):
    nyq = 0.5 * fs
    low = lowcut / nyq
    high = highcut / nyq
    b, a = butter(order, [low, high], btype='bandstop')
    return b, a

def butter_stopband_filter(data, lowcut, highcut, fs, order=5):
    b, a = butter_stopband(lowcut, highcut, fs, order=order)
    y = filtfilt(b, a, data)
    return y

def wavelet_denoising(data, wavelet='db4', level=3):
    coeffs = pywt.wavedec(data, wavelet, level=level)
    threshold = (coeffs[-1]**2).mean()**0.5
    coeffs[1:] = (pywt.threshold(i, value=threshold, mode='soft') for i in coeffs[1:])
    return pywt.waverec(coeffs, wavelet)

def calculate_score(metrics):
    max_score = 100  # 假设满分为100
    individual_scores = {}  # 存储各项指标的得分
    total_score = 0  # 综合得分

    # 设置指标的健康阈值和评分规则
    thresholds = {
        'bpm': (60, 100),
        'ibi': (500, 1000),
        'sdnn': (20, 50),
        'sdsd': (15, 30),
        'rmssd': (20, 50),
        'pnn20': (0, 1),
        'pnn50': (0, 1),
        'hr_mad': (0, 20),
        'sd1': (10, 30),
        'sd2': (10, 30),
        's': (500, 1500),
        'sd1/sd2': (0, 1),
        'breathingrate': (0.1, 0.3),
    }

    for key, value in metrics.items():
        if key in thresholds:
            low, high = thresholds[key]
            if value < low:
                individual_scores[key] = 60
            elif value > high:
                individual_scores[key] = 60
            else:
                # 线性映射
                score = (value - low) / (high - low) * (max_score / len(thresholds))+95
                individual_scores[key] = score
                total_score += score

    # 计算综合得分
    final_score = total_score / len(thresholds)  # 可以根据需求调整计算方式

    return individual_scores, final_score


def process_data(mat_data_path):
    # 读取.mat文件
    mat_data = loadmat(mat_data_path)

    # 提取数据
    v = mat_data['v']
    fs = mat_data['fs'][0, 0]  # fs是标量

    # 检查采样率并调整到400Hz
    target_fs = 444
    if fs != target_fs:
        # 计算缩放因子
        scale_factor = target_fs / fs
        # 降采样或升采样
        v = resample(v[:, 0], int(len(v[:, 0]) * scale_factor))
        # 更新采样率
        fs = target_fs

    # 归一化数据
    v_mean = np.mean(v)
    v_std = np.std(v)
    v = (v - v_mean) / v_std

    # 应用滤波器
    lowcut = 0.7
    highcut = 100
    stopband = [48, 52]

    # 应用带通滤波器
    filtered_signal = butter_bandpass_filter(v, lowcut, highcut, fs, order=1)

    # 应用48-52Hz带阻滤波器
    filtered_signal = butter_stopband_filter(filtered_signal, stopband[0], stopband[1], fs, order=2)

    # 小波去噪
    denoised_signal = wavelet_denoising(filtered_signal, wavelet='db4', level=3)

    # 重新缩放到原始范围
    denoised_signal = denoised_signal * v_std + v_mean

    # 计算指标
    wd, metrics = hp.process(denoised_signal, fs)

    # 准备 metrics_list 为字典
    metrics_list = {key: value for key, value in metrics.items()}

    # 计算健康得分
    individual_scores, final_score = calculate_score(metrics)

    return denoised_signal, metrics_list, individual_scores, final_score, fs
