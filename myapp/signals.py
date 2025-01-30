from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Utilisateur, Guide, Serrefils

@receiver(post_save, sender=Guide)
def set_guide_role(sender, instance, created, **kwargs):
    if created:
        utilisateur = instance.utilisateur
        utilisateur.role = 'Guide'
        utilisateur.is_employee = True
        utilisateur.save()

@receiver(post_save, sender=Serrefils)
def set_serrefils_role(sender, instance, created, **kwargs):
    if created:
        utilisateur = instance.utilisateur
        utilisateur.role = 'Serrefils'  
        utilisateur.is_employee = True  
        utilisateur.save()  
