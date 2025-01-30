from rest_framework import generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Utilisateur, Presence, Etage, Guide, Serrefils, Employe
from .serializers import GuideSerializer, SerrefilsSerializer, UtilisateurSerializer
from django.contrib.auth.hashers import check_password
from django.utils.timezone import now
import json
from django.db import IntegrityError
from rest_framework import status as http_status
from rest_framework import permissions
from rest_framework import viewsets
from .models import Maintenance
from .serializers import MaintenanceSerializer
from rest_framework.decorators import api_view, permission_classes
from .permissions import CustomPermission
from django.db.models import Count, Q
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Maintenance
from .serializers import MaintenanceSerializer
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view
from rest_framework.response import Response
# views.py

from django.db.models import Count, Q
from django.utils import timezone
from datetime import timedelta
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Maintenance
from .serializers import MaintenanceSerializer
from django.db.models import Max, Subquery, OuterRef



class LoginView(APIView):
    def post(self, request):
        email = request.data.get('email').lower()
        password = request.data.get('password')

        try:
            user = Utilisateur.objects.get(email__iexact=email)
            password_check = check_password(password, user.password)

            if password_check:
                refresh = RefreshToken.for_user(user)
                print("Authenticated User:", user.email)
                print("Is Admin:", user.is_admin)  
                return Response({
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                    'user_id': user.id,
                    'role': user.role,
                    'is_admin': user.is_admin
                })
            else:
                return Response({'error': 'Invalid email or password'}, status=status.HTTP_401_UNAUTHORIZED)
        except Utilisateur.DoesNotExist:
            return Response({'error': 'Invalid email or password'}, status=status.HTTP_401_UNAUTHORIZED)

@csrf_exempt
def update_presence(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            print("Data received from Flutter:", data)
            utilisateur_id = data.get('user_id')
            presence_status = data.get('status')
            
            if utilisateur_id is None or presence_status is None:
                return JsonResponse({'success': False, 'message': 'Missing user_id or status in the request'}, status=http_status.HTTP_400_BAD_REQUEST)

            try:
                utilisateur_id = int(utilisateur_id)
            except ValueError:
                return JsonResponse({'success': False, 'message': 'Invalid user_id'}, status=http_status.HTTP_400_BAD_REQUEST)

            if isinstance(presence_status, str):
                presence_status = presence_status.lower() == 'true'
            else:
                presence_status = bool(presence_status)

            utilisateur = Utilisateur.objects.get(id=utilisateur_id)
            etage = utilisateur.etage  

            if etage is None:
                return JsonResponse({'success': False, 'message': 'Etage does not exist for the user'}, status=http_status.HTTP_400_BAD_REQUEST)

            presence = Presence(utilisateur=utilisateur, etage=etage, date_heure=now(), status=presence_status)
            presence.save()

            return JsonResponse({'success': True, 'message': 'Presence updated successfully'})
        except Utilisateur.DoesNotExist:
            return JsonResponse({'success': False, 'message': 'User does not exist'}, status=http_status.HTTP_400_BAD_REQUEST)
        except IntegrityError as e:
            return JsonResponse({'success': False, 'message': 'IntegrityError: {}'.format(str(e))}, status=http_status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=http_status.HTTP_400_BAD_REQUEST)

    return JsonResponse({'success': False, 'message': 'Invalid request method'}, status=http_status.HTTP_405_METHOD_NOT_ALLOWED)



@api_view(['GET'])
def get_presence_status(request, user_id):
    try:
        presence = Presence.objects.filter(utilisateur__id=user_id).order_by('-date_heure').first()
        if presence:
            return JsonResponse({'status': presence.status}, status=200)
        else:
            return JsonResponse({'status': 'absent'}, status=200)
    except Utilisateur.DoesNotExist:
        return JsonResponse({'success': False, 'message': 'User does not exist'}, status=400)
    except Exception as e:
        return JsonResponse({'success': False, 'message': str(e)}, status=400)

class CreateAdminUserView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        data = request.data.copy()
        data['is_admin'] = True  

        serializer = UtilisateurSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class GuideListView(generics.ListCreateAPIView):
    queryset = Guide.objects.all()
    serializer_class = GuideSerializer
    permission_classes = [CustomPermission]

class GuideDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Guide.objects.all()
    serializer_class = GuideSerializer
    permission_classes = [CustomPermission]
    def patch(self, request, *args, **kwargs):
        return self.partial_update(request, *args, **kwargs)

class GuideViewSet(viewsets.ModelViewSet):
    queryset = Guide.objects.all()
    serializer_class = GuideSerializer
    permission_classes = [CustomPermission]
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        guide = serializer.save()
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)



class SerrefilsListView(generics.ListCreateAPIView):
    queryset = Serrefils.objects.all()
    serializer_class = SerrefilsSerializer
    permission_classes = [CustomPermission]


class SerrefilsDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Serrefils.objects.all()
    serializer_class = SerrefilsSerializer
    permission_classes = [CustomPermission]
    def patch(self, request, *args, **kwargs):
        return self.partial_update(request, *args, **kwargs)

class SerrefilsViewSet(viewsets.ModelViewSet):
    queryset = Serrefils.objects.all()
    serializer_class = SerrefilsSerializer
    permission_classes = [CustomPermission]
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serrefils = serializer.save()
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)


class MaintenanceViewSet(viewsets.ModelViewSet):
    queryset = Maintenance.objects.all()
    serializer_class = MaintenanceSerializer




@api_view(['GET', 'POST'])
def maintenance_list(request):
    if request.method == 'GET':
        maintenances = Maintenance.objects.all()
        serializer = MaintenanceSerializer(maintenances, many=True)
        return Response(serializer.data)
    
    if request.method == 'POST':
        serializer = MaintenanceSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


    
class EtageListView(APIView):
    def get(self, request):
        etages = Etage.objects.all().values('id', 'number')
        return Response(list(etages))






@api_view(['GET'])
@permission_classes([CustomPermission])
def presence_statistics(request):
    latest_status_date = Presence.objects.filter(utilisateur=OuterRef('utilisateur')).order_by('-date_heure').values('date_heure')[:1]

    latest_presences = Presence.objects.filter(date_heure=Subquery(latest_status_date)).order_by('utilisateur')

    presence_stats = (latest_presences.filter(status=True)
                      .values('etage__number')
                      .annotate(count=Count('utilisateur'))
                      .order_by('etage__number'))

    data = {stat['etage__number']: stat['count'] for stat in presence_stats}

    all_etages = Etage.objects.all().values_list('number', flat=True)
    for etage in all_etages:
        data.setdefault(etage, 0)

    return Response(data)





class MonthlyAttendanceReportView(APIView):
    permission_classes = [CustomPermission]
    def get(self, request):
        today = timezone.now().date()
        first_day_of_month = today.replace(day=1)
        last_day_of_month = (first_day_of_month + timedelta(days=32)).replace(day=1) - timedelta(days=1)

        presences = Presence.objects.filter(date_heure__date__range=[first_day_of_month, last_day_of_month])

        total_days = (last_day_of_month - first_day_of_month).days + 1

        report = []

        etages = Etage.objects.all()

        for etage in etages:
            users = Utilisateur.objects.filter(etage=etage)

            total_present_days = 0
            for user in users:
                user_presences = presences.filter(utilisateur=user, status=True).values('date_heure__date').distinct().count()
                total_present_days += user_presences

            if users.count() > 0:
                attendance_rate = (total_present_days / (users.count() * total_days)) * 100
            else:
                attendance_rate = 0

            report.append({
                'etage': etage.number,
                'attendance_rate': attendance_rate,
                'total_days': total_days,
                'total_present_days': total_present_days,
                'user_count': users.count(),
            })

        return Response(report)

@api_view(['GET'])
def profile_details(request, user_id):
    try:
        guide = Guide.objects.select_related('utilisateur__etage').get(utilisateur_id=user_id)
        last_presence = guide.utilisateur.presence_set.latest('date_heure').date_heure.strftime('%H:%M') if guide.utilisateur.presence_set.exists() else None
        profile_data = {
            'nom': guide.utilisateur.nom,
            'prenom': guide.utilisateur.prenom,
            'email': guide.utilisateur.email,
            'etage': guide.etage.number if guide.etage else None,
            'role': guide.utilisateur.role,
            'last_presence': last_presence
        }
        return Response(profile_data)
    except Guide.DoesNotExist:
        try:
            serrefil = Serrefils.objects.select_related('utilisateur__etage').get(utilisateur_id=user_id)
            last_presence = serrefil.utilisateur.presence_set.latest('date_heure').date_heure.strftime('%H:%M') if serrefil.utilisateur.presence_set.exists() else None
            profile_data = {
                'nom': serrefil.utilisateur.nom,
                'prenom': serrefil.utilisateur.prenom,
                'email': serrefil.utilisateur.email,
                'etage': serrefil.etage.number if serrefil.etage else None,
                'role': serrefil.utilisateur.role,
                'last_presence': last_presence
            }
            return Response(profile_data)
        except Serrefils.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)