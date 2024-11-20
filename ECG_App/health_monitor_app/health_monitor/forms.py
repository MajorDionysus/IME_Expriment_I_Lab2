from django import forms

class DataUploadForm(forms.Form):
    mat_data = forms.FileField(label='MAT 数据文件')  # MAT数据文件
