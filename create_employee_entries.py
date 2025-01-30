# create_employee_entries.py

import os
import django

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')
django.setup()

# Import your models
from myapp.models import Utilisateur, Employe

# Create employee entries
def create_employee_entries():
    # Truncate Employe table
    Employe.objects.all().delete()

    # Get existing HSE, Guide, and Serrefils
    hse = Utilisateur.objects.get(role='HSE')
    guides = Utilisateur.objects.filter(role='Guide')
    serrefils = Utilisateur.objects.filter(role='Serrefils')

    # Create Employe entries
    Employe.objects.create(utilisateur=hse)
    for guide in guides:
        Employe.objects.create(utilisateur=guide)
    for serrefil in serrefils:
        Employe.objects.create(utilisateur=serrefil)

if __name__ == "__main__":
    create_employee_entries()
