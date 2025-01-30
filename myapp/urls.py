from django.urls import path
from .views import (
    LoginView,
    update_presence,
    GuideDetailView,
    SerrefilsListView,
    SerrefilsDetailView,
    maintenance_list,
    EtageListView,
    MonthlyAttendanceReportView,
    SerrefilsDetailView,
    GuideViewSet,
    SerrefilsViewSet,
    GuideListView,
    get_presence_status,

)
from .views import CreateAdminUserView
from . import views

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('update_presence/', update_presence, name='update_presence'),
    path('guides/', GuideListView.as_view(), name='guide-list-create'),
    path('guides/<int:pk>/', GuideDetailView.as_view(), name='guide-detail'),
    path('serrefils/', SerrefilsListView.as_view(), name='serrefils-list-create'),
    path('serrefils/<int:pk>/', SerrefilsDetailView.as_view(), name='serrefils-detail'),
    path('create-admin/', CreateAdminUserView.as_view(), name='create-admin'),
    path('maintenance/', maintenance_list, name='maintenance-list-create'),
    path('etages/', EtageListView.as_view(), name='etage-list'),
    path('presence-statistics/', views.presence_statistics, name='presence-statistics'),
    path('get_presence_status/<int:user_id>/', get_presence_status, name='get_presence_status'),
    path('monthly-attendance-report/', MonthlyAttendanceReportView.as_view(), name='monthly-attendance-report'),
    path('profile/<int:user_id>/', views.profile_details, name='profile-details'),

]




