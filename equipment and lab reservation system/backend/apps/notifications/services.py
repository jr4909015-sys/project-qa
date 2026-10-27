from .models import Notification


def notify_user(*, recipient, title, message, reservation=None):
    return Notification.objects.create(
        recipient=recipient, title=title, message=message, reservation=reservation
    )