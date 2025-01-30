from django.shortcuts import render
from django.db.models import Count, Q, Subquery, OuterRef
from django.utils import timezone
from datetime import timedelta
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.shortcuts import render
from django.db.models import Count, OuterRef, Subquery
from myapp.models import Etage, Presence
from myapp import models
from django.contrib.auth import authenticate, login as auth_login
from django.shortcuts import redirect, render
from django.views import View
from .forms import CustomLoginForm
from django.contrib.auth.decorators import login_required
from django.shortcuts import get_object_or_404
from django.contrib.auth.decorators import login_required
from .decorators import admin_required
from django.shortcuts import render
from django.utils import timezone
from datetime import timedelta
from myapp.models import Etage, Presence, Maintenance
from django.db.models import Count
from django.db.models.functions import TruncDate
from django.shortcuts import render
from myapp.models import Guide, Serrefils
from django.contrib.auth import logout
from django.contrib.auth.mixins import LoginRequiredMixin
from django.utils.decorators import method_decorator


class CustomLoginView(View):
    form_class = CustomLoginForm
    template_name = 'employee_register/login.html'

    def get(self, request):
        form = self.form_class()
        return render(request, self.template_name, {'form': form})

    def post(self, request):
        form = self.form_class(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']
            password = form.cleaned_data['password']
            user = authenticate(request, email=email, password=password)
            if user is not None:
                auth_login(request, user)
                if user.is_admin:
                    return redirect('webapp:admin_dashboard')
            else:
                form.add_error(None, 'Invalid email or password')
        return render(request, self.template_name, {'form': form})

class AdminRequiredMixin:
    @method_decorator(admin_required)
    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)

def get_latest_presences():
    latest_presence_subquery = Presence.objects.filter(
        utilisateur_id=OuterRef('utilisateur_id')
    ).order_by('-date_heure').values('date_heure')[:1]

    latest_presences = Presence.objects.filter(
        date_heure=Subquery(latest_presence_subquery)
    ).select_related('utilisateur', 'etage').order_by('utilisateur__id')

    return latest_presences

class AdminDashboardView(LoginRequiredMixin, AdminRequiredMixin, View):
    def get(self, request):
        latest_presences = get_latest_presences()
        all_floors = Etage.objects.all()
        presence_stats = (latest_presences
                          .filter(status=True)
                          .values('etage__number')
                          .annotate(count=Count('utilisateur'))
                          .order_by('etage__number'))

        floor_presence_counts = {floor.number: 0 for floor in all_floors}
        for stat in presence_stats:
            floor_presence_counts[stat['etage__number']] = stat['count']
        today = timezone.now()
        thirty_days_ago = today - timedelta(days=30)
        floor_data = []
        for floor in all_floors:
            presence_count = Presence.objects.filter(
                etage=floor,
                date_heure__gte=thirty_days_ago,
                date_heure__lte=today,
                status=True
            ).annotate(date=TruncDate('date_heure')).values('date').distinct().count()
            presence_rate = (presence_count / 30) * 100
            floor_data.append({
                'floor_number': floor.number,
                'presence_count': presence_count,
                'presence_rate': round(presence_rate, 2)
            })
        context = {
            'floor_presence_counts': floor_presence_counts,
            'floor_data': floor_data
        }
        return render(request, 'employee_register/admin_dashboard.html', context)

@login_required
@admin_required
def user_info(request):
    if not isinstance(request.user, Utilisateur):
        # Handle the case where request.user is not Utilisateur instance
        # Redirect to login or handle error
        pass

    utilisateur = request.user

    context = {
        'utilisateur': utilisateur,
    }

    return render(request, 'employee_register/user_info.html', context)

@login_required
@admin_required
def guide_list(request):
    last_presence_subquery = Presence.objects.filter(
        utilisateur=OuterRef('utilisateur')
    ).order_by('-date_heure').values('status')[:1]

    guides = Guide.objects.select_related('utilisateur', 'etage').annotate(
        last_status=Subquery(last_presence_subquery)
    )
    
    return render(request, 'employee_register/guide_list.html', {'guides': guides})

@login_required
@admin_required
def serrefils_list(request):
    last_presence_subquery = Presence.objects.filter(
        utilisateur=OuterRef('utilisateur')
    ).order_by('-date_heure').values('status')[:1]

    serrefils = Serrefils.objects.select_related('utilisateur', 'etage').annotate(
        last_status=Subquery(last_presence_subquery)
    )

    return render(request, 'employee_register/serrefils_list.html', {'serrefils': serrefils})

@login_required
@admin_required
def maintenance_list(request):
    fire_maintenances = Maintenance.objects.filter(type='Extincteur')
    smoke_maintenances = Maintenance.objects.filter(type='Alarme')
    context = {
        'fire_maintenances': fire_maintenances,
        'smoke_maintenances': smoke_maintenances,
    }
    return render(request, 'employee_register/maintenance_list.html', context)

from django.contrib.auth import logout

def logout_view(request):
    logout(request)
    return redirect('webapp:login')