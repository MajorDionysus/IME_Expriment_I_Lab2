import os
from django.shortcuts import render
from .forms import DataUploadForm
from .services import process_data  # 假设你的代码放在 services.py 中

def index(request):
    if request.method == 'POST':
        form = DataUploadForm(request.POST, request.FILES)
        if form.is_valid():
            mat_data_file = request.FILES['mat_data']  # 获取 MAT 数据文件

            # 检查并创建 temp 目录
            temp_dir = 'temp'
            if not os.path.exists(temp_dir):
                os.makedirs(temp_dir)

            # 暂时保存上传的文件
            mat_data_path = os.path.join(temp_dir, mat_data_file.name)
            with open(mat_data_path, 'wb+') as destination:
                for chunk in mat_data_file.chunks():
                    destination.write(chunk)

            # 处理数据
            denoised_signal, metrics_list, individual_scores,final_score, fs = process_data(mat_data_path)
            # 将 denoised_signal 转换为列表以便在模板中使用
            denoised_signal = denoised_signal.tolist()
            # 准备报告数据
            report_data = {
                'denoised_signal': denoised_signal,
                'metrics_list': metrics_list,
                'individual_scores': individual_scores,  # 各项得分
                'score': final_score,  # 综合得分
                'fs': fs
            }

            # 渲染报告页面
            return render(request, 'report.html', {'report_data': report_data})

    else:
        form = DataUploadForm()

    return render(request, 'index.html', {'form': form})
