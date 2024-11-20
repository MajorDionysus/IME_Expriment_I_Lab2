from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('health_monitor.urls')),  # 包含健康监护应用的URL
]
