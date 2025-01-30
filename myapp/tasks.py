import logging
from celery import shared_task
from django.core.mail import send_mail
from django.apps import apps

logger = logging.getLogger(__name__)

@shared_task
def send_maintenance_notification(maintenance_type, etage_id, maintenance_date):
    logger.info(f"Sending notification for: {maintenance_type}, {etage_id}, {maintenance_date}")
    try:
        Etage = apps.get_model('myapp', 'Etage')
        etage = Etage.objects.get(pk=etage_id)
        subject = 'Maintenance Reminder'
        message = f'Reminder: Maintenance for {maintenance_type} on floor {etage} is due on {maintenance_date}. Please prepare accordingly.'
        recipient_email = 'batoulbatou250948@gmail.com'
        
        send_mail(subject, message, 'senderappsiemens@gmail.com', [recipient_email])
        logger.info("Notification sent successfully")
    except Exception as e:
        logger.error(f"Error sending notification: {e}")
    
    return "Notification task completed"
