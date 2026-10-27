from .models import AuditLog


def record_audit(*, actor, action, instance, summary):
    return AuditLog.objects.create(
        actor=actor,
        action=action,
        object_type=instance._meta.label,
        object_id=instance.pk,
        summary=summary,
    )