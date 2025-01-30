# models.py
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.db.models.signals import post_delete
from django.core.mail import send_mail
from django.utils import timezone
from .tasks import send_maintenance_notification
from datetime import timedelta  

class Etage(models.Model):
    number = models.IntegerField(unique=True)

    def __str__(self):
        return str(self.number)

class MyUserManager(BaseUserManager):
    def create_user(self, email, nom, prenom, contact, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        etage_number = extra_fields.pop('etage', None)
        etage = Etage.objects.get_or_create(number=etage_number)[0] if etage_number else None
        user = self.model(email=email, nom=nom, prenom=prenom, contact=contact, etage=etage, **extra_fields)
        if password:
            user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, nom, prenom, contact, password=None, **extra_fields):
        extra_fields.setdefault('is_admin', True)
        extra_fields.setdefault('is_employee', False)
        return self.create_user(email, nom, prenom, contact, password, **extra_fields)

class Utilisateur(AbstractBaseUser):
    id = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=50)
    prenom = models.CharField(max_length=50)
    email = models.EmailField(unique=True)
    contact = models.CharField(max_length=20)
    is_admin = models.BooleanField(default=False)
    is_employee = models.BooleanField(default=False)
    role = models.CharField(max_length=10, choices=[
        ('', 'Select Role'),
        ('HSE', 'HSE'),
        ('Guide', 'Guide'),
        ('Serrefils', 'Serrefils'),
    ], blank=True, null=True, default='')
    etage = models.ForeignKey(Etage, on_delete=models.SET_NULL, null=True, blank=True)

    objects = MyUserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['nom', 'prenom', 'contact']

    def __str__(self):
        return self.email

    def save(self, *args, **kwargs):
        if self.is_admin:
            self.is_employee = False
            self.role = ''
        elif self.role:
            self.is_employee = True
        super(Utilisateur, self).save(*args, **kwargs)

    class Meta:
        verbose_name = "Utilisateur"
        verbose_name_plural = "Utilisateurs"


@receiver(post_save, sender=Utilisateur)
def create_employe(sender, instance, created, **kwargs):
    if created:
        if instance.role in ['Guide', 'Serrefils', 'HSE']:
            employe, created = Employe.objects.get_or_create(utilisateur=instance)
            
            if instance.role == 'Guide':
                Guide.objects.get_or_create(utilisateur=instance, etage=instance.etage)
            elif instance.role == 'Serrefils':
                Serrefils.objects.get_or_create(utilisateur=instance, etage=instance.etage)
            elif instance.role == 'HSE':
                HSE.objects.get_or_create(utilisateur=instance, etage=instance.etage)


class Employe(models.Model):
    utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE)

class Guide(models.Model):
    utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE)
    etage = models.ForeignKey(Etage, on_delete=models.SET_NULL, null=True, blank=True)
    
    class Meta:
        verbose_name = "Guide"
        verbose_name_plural = "Guides"

class Serrefils(models.Model):
    utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE)
    etage = models.ForeignKey(Etage, on_delete=models.SET_NULL, null=True, blank=True)
    class Meta:
        verbose_name = "Serrefils"
        verbose_name_plural = "Serrefils"

class Presence(models.Model):
    id_presence = models.AutoField(primary_key=True)
    utilisateur = models.ForeignKey(Utilisateur, on_delete=models.CASCADE)
    etage = models.ForeignKey(Etage, on_delete=models.CASCADE)
    date_heure = models.DateTimeField(auto_now_add=True)
    status = models.BooleanField()

    def __str__(self):
        return f"{self.utilisateur.email} - {self.etage.number} - {self.date_heure}"
    class Meta:
        verbose_name = "Presence"
        verbose_name_plural = "Presences"

class HSE(models.Model):
    utilisateur = models.OneToOneField(Utilisateur, on_delete=models.CASCADE)
    etage = models.ForeignKey(Etage, on_delete=models.SET_NULL, null=True, blank=True)
    
    class Meta:
        verbose_name = "HSE"
        verbose_name_plural = "HSE"

@receiver(post_delete, sender=Guide)
@receiver(post_delete, sender=Serrefils)
@receiver(post_delete, sender=HSE)
def delete_related_objects(sender, instance, **kwargs):
    Utilisateur.objects.filter(id=instance.utilisateur.id).delete()
    Employe.objects.filter(utilisateur_id=instance.utilisateur.id).delete()


from django.db import models
from django.utils import timezone
from datetime import timedelta

class Maintenance(models.Model):
    TYPE_CHOICES = [
        ('Extincteur', 'Extincteur'),
        ('Alarme', 'Alarme'),
    ]
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    date_de_maintenance = models.DateField()
    etage = models.ForeignKey('Etage', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.type} - {self.date_de_maintenance} - {self.etage}"

    def save(self, *args, **kwargs):
        is_new = self.pk is None
        super().save(*args, **kwargs)
        if is_new:
            self.schedule_notification()

    def schedule_notification(self):
        from myapp.tasks import send_maintenance_notification  
        notification_date = self.date_de_maintenance + timedelta(days=11*30)
        send_maintenance_notification.apply_async(
            args=[self.type, self.etage_id, self.date_de_maintenance], 
            eta=notification_date
        )


