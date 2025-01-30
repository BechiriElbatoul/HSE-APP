from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import Utilisateur, Guide, Serrefils, Employe, Etage, Maintenance
from rest_framework.response import Response
from rest_framework import status

class EtageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Etage
        fields = ['id', 'number']

class UtilisateurSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True) 
    etage = serializers.IntegerField(write_only=True)

    class Meta:
        model = Utilisateur
        fields = ['id', 'nom', 'prenom', 'email', 'contact', 'role', 'password', 'is_admin', 'is_employee', 'etage']
        extra_kwargs = {
            'is_admin': {'read_only': True},  
            'is_employee': {'read_only': True},  
            'role': {'required': False},  
        }
    def update(self, instance, validated_data):
        etage_id = validated_data.pop('etage', None)
        if etage_id is not None:
            instance.etage = Etage.objects.get(id=etage_id)

        for attr, value in validated_data.items():
            if attr == 'password':
                value = make_password(value)
            setattr(instance, attr, value)

        instance.save()
        return instance
class GuideSerializer(serializers.ModelSerializer):
    utilisateur = UtilisateurSerializer()

    class Meta:
        model = Guide
        fields = ['id','utilisateur', 'etage']

    def create(self, validated_data):
        utilisateur_data = validated_data.pop('utilisateur')
        etage_number = utilisateur_data.pop('etage')

        etage, created = Etage.objects.get_or_create(number=etage_number)

        utilisateur = Utilisateur.objects.create(**utilisateur_data, etage=etage)
        utilisateur.set_password(utilisateur_data['password'])
        utilisateur.save()

        employe, created = Employe.objects.get_or_create(utilisateur=utilisateur)
        guide = Guide.objects.create(utilisateur=utilisateur, etage=etage)
        return guide
    
    def update(self, instance, validated_data):
        utilisateur_data = validated_data.pop('utilisateur')
        utilisateur = instance.utilisateur

        etage_id = utilisateur_data.pop('etage')
        utilisateur.etage = Etage.objects.get(id=etage_id)

        for attr, value in utilisateur_data.items():
            if attr == 'password':
                value = make_password(value)
            setattr(utilisateur, attr, value)
        utilisateur.save()

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        return instance




class SerrefilsSerializer(serializers.ModelSerializer):
    utilisateur = UtilisateurSerializer()

    class Meta:
        model = Serrefils
        fields = ['id', 'utilisateur', 'etage']

    def create(self, validated_data):
        utilisateur_data = validated_data.pop('utilisateur')
        etage_number = utilisateur_data.pop('etage')

        etage, created = Etage.objects.get_or_create(number=etage_number)

        utilisateur = Utilisateur.objects.create(**utilisateur_data, etage=etage)
        utilisateur.set_password(utilisateur_data['password'])
        utilisateur.save()

        employe, created = Employe.objects.get_or_create(utilisateur=utilisateur)
        serrefils = Serrefils.objects.create(utilisateur=utilisateur, etage=etage)
        return serrefils
    
    def update(self, instance, validated_data):
        utilisateur_data = validated_data.pop('utilisateur')
        utilisateur = instance.utilisateur

        etage_id = utilisateur_data.pop('etage')
        utilisateur.etage = Etage.objects.get(id=etage_id)

        for attr, value in utilisateur_data.items():
            if attr == 'password':
                value = make_password(value)
            setattr(utilisateur, attr, value)
        utilisateur.save()

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        return instance


class EmployeSerializer(serializers.ModelSerializer):
    utilisateur = UtilisateurSerializer()

    class Meta:
        model = Employe
        fields = ['id', 'utilisateur']

class MaintenanceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Maintenance
        fields = '__all__'
