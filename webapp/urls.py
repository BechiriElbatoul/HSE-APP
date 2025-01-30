from django.urls import path
from .views import CustomLoginView, user_info, AdminDashboardView, logout_view
from . import views

app_name = 'webapp'

urlpatterns = [
    path('login/', CustomLoginView.as_view(), name='login'),
    path('user-info/', user_info, name='user_info'),
    path('admin-dashboard/', AdminDashboardView.as_view(), name='admin_dashboard'),
    path('guides/', views.guide_list, name='guide_list'),
    path('serrefils/', views.serrefils_list, name='serrefils_list'),
    path('maintenance/', views.maintenance_list, name='maintenance_list'),
    path('logout/', logout_view, name='logout'),
]
